defmodule Ignite.LiveView.Handler do
  @behaviour :cowboy_websocket

  alias Ignite.LiveView
  alias Ignite.LiveView.Engine

  require Logger

  @impl true
  def init(req, state) do
    cookie_header = :cowboy_req.header("cookie", req, "")
    cookies = Ignite.Session.parse_cookies(cookie_header)

    session =
      case Ignite.Session.decode(Map.get(cookies, Ignite.Session.cookie_name())) do
        {:ok, data} -> data
        :error -> %{}
      end

    {:cowboy_websocket, req, Map.put(state, :session, session)}
  end

  # On mount: send statics + dynamics
  @impl true
  def websocket_init(state) do
    view_module = state.view
    session = Map.get(state, :session, %{})

    case apply(view_module, :mount, [%{}, session]) do
      {:ok, initial_assigns} ->
        # Render and collect initial component state
        {statics, dynamics} = Engine.render(view_module, initial_assigns)
        assigns = LiveView.collect_components(initial_assigns)

        # Extract pending stream operations (initial items from mount)
        {streams_payload, assigns} = Ignite.LiveView.Stream.extract_stream_ops(assigns)

        Logger.info("[LiveView] Mounted #{inspect(view_module)}")

        # Include streams in mount payload if present
        payload_map = %{s: statics, d: dynamics}

        payload_map =
          if streams_payload,
            do: Map.put(payload_map, :streams, streams_payload),
            else: payload_map

        payload = Jason.encode!(payload_map)

        {:reply, {:text, payload},
         %{view: view_module, assigns: assigns, prev_dynamics: dynamics}}
    end
  end

  @impl true
  def websocket_handle({:text, json}, state) do
    case Jason.decode(json) do
      {:ok, %{"event" => "__upload_validate__", "params" => %{"name" => name, "entries" => entries}}} ->
        upload_name = String.to_atom(name)
        new_assigns = Ignite.LiveView.UploadHelpers.validate_entries(state.assigns, upload_name, entries)

        # Let the view handle validation if it defines handle_event("validate", ...)
        new_assigns =
          if function_exported?(state.view, :handle_event, 3) do
            case apply(state.view, :handle_event, ["validate", %{"name" => name}, new_assigns]) do
              {:noreply, a} -> a
              _ -> new_assigns
            end
          else
            new_assigns
          end

        send_render_update_with_upload_config(state, new_assigns, upload_name)

      {:ok, %{"event" => "__upload_complete__", "params" => %{"name" => name, "ref" => ref}}} ->
        upload_name = String.to_atom(name)
        new_assigns = Ignite.LiveView.UploadHelpers.mark_complete(state.assigns, upload_name, ref)
        send_render_update(state, new_assigns)

      {:ok, %{"event" => event, "params" => params}} ->
        # 1. Try routing to a component first
        {new_assigns, is_component_event} = handle_possible_component_event(event, params, state)

        # 2. If not a component event, route to parent LiveView
        new_assigns =
          if is_component_event do
            new_assigns
          else
            case apply(state.view, :handle_event, [event, params, state.assigns]) do
              {:noreply, assigns} -> assigns
              _ -> state.assigns
            end
          end

        # 3. Handle possible redirect
        case Map.pop(new_assigns, :__redirect__) do
          {nil, clean_assigns} ->
            send_render_update(state, clean_assigns)

          {redirect_info, clean_assigns} ->
            payload = Jason.encode!(%{redirect: redirect_info})
            {:reply, {:text, payload}, %{state | assigns: clean_assigns}}
        end

      _ ->
        {:ok, state}
    end
  end

  # Binary frames carry file upload chunks
  # Protocol: [2 bytes: ref_len][ref_len bytes: ref_string][rest: chunk_data]
  @impl true
  def websocket_handle({:binary, data}, state) do
    case data do
      <<ref_len::16, ref::binary-size(ref_len), chunk_data::binary>> ->
        new_assigns = Ignite.LiveView.UploadHelpers.receive_chunk(state.assigns, ref, chunk_data)
        send_render_update(state, new_assigns)

      _ ->
        Logger.warning("[LiveView] Malformed binary upload frame")
        {:ok, state}
    end
  end

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  # Server-push: handle messages sent to this process (e.g. PubSub, timers)
  @impl true
  def websocket_info(msg, state) do
    if function_exported?(state.view, :handle_info, 2) do
      case apply(state.view, :handle_info, [msg, state.assigns]) do
        {:noreply, new_assigns} ->
          send_render_update(state, new_assigns)

        _ ->
          {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  # --- Helpers ---

  defp handle_possible_component_event(event, params, state) do
    case String.split(event, ":", parts: 2) do
      [component_id, component_event] ->
        components = Map.get(state.assigns, :__components__, %{})

        case Map.get(components, component_id) do
          {module, comp_assigns} ->
            {:noreply, new_comp_assigns} =
              apply(module, :handle_event, [component_event, params, comp_assigns])

            new_components = Map.put(components, component_id, {module, new_comp_assigns})
            {Map.put(state.assigns, :__components__, new_components), true}

          nil ->
            {state.assigns, false}
        end

      _ ->
        {state.assigns, false}
    end
  end

  defp send_render_update(state, assigns) do
    {_statics, new_dynamics} = Engine.render(state.view, assigns)
    final_assigns = LiveView.collect_components(assigns)

    # Compute sparse diff against previous dynamics
    diff_payload =
      case Map.get(state, :prev_dynamics) do
        nil -> new_dynamics
        prev -> Engine.diff(prev, new_dynamics)
      end

    # Extract pending stream operations
    {streams_payload, final_assigns} = Ignite.LiveView.Stream.extract_stream_ops(final_assigns)

    new_state = %{state | assigns: final_assigns, prev_dynamics: new_dynamics}

    # Include streams in payload if present
    payload_map = %{d: diff_payload}

    payload_map =
      if streams_payload,
        do: Map.put(payload_map, :streams, streams_payload),
        else: payload_map

    payload = Jason.encode!(payload_map)
    {:reply, {:text, payload}, new_state}
  end

  defp send_render_update_with_upload_config(state, assigns, upload_name) do
    {_statics, new_dynamics} = Engine.render(state.view, assigns)
    final_assigns = LiveView.collect_components(assigns)

    # Compute sparse diff against previous dynamics
    diff_payload =
      case Map.get(state, :prev_dynamics) do
        nil -> new_dynamics
        prev -> Engine.diff(prev, new_dynamics)
      end

    # Extract upload config to send to client
    upload_config = Ignite.LiveView.UploadHelpers.build_upload_config(final_assigns, upload_name)

    new_state = %{state | assigns: final_assigns, prev_dynamics: new_dynamics}

    payload_map = %{d: diff_payload}

    payload_map =
      if upload_config,
        do: Map.put(payload_map, :upload, upload_config),
        else: payload_map

    payload = Jason.encode!(payload_map)
    {:reply, {:text, payload}, new_state}
  end
end
