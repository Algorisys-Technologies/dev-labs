defmodule Ignite.LiveView.Handler do
  @moduledoc """
  A Cowboy WebSocket handler for LiveView.
  
  Manages the lifecycle of a LiveView connection, including mounting,
  event handling, and pushing real-time updates to the client.
  """
  @behaviour :cowboy_websocket

  alias Ignite.LiveView.Engine
  alias Ignite.LiveView.Diff
  alias Ignite.LiveView.Stream
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

  # Initial state is empty, wait for lv:join
  @impl true
  def websocket_init(state) do
    Logger.error("[Handler] websocket_init")
    # Subscribe to common topics if needed, but we don't know the module yet.
    # We will handle module-specific subscriptions in handle_join.
    {:ok, Map.put(state, :mounted, false)}
  end

  @impl true
  def websocket_handle({:text, json}, state) do
    case Jason.decode!(json) do
      %{"topic" => "lv:join", "payload" => %{"module" => module_str}} ->
        handle_join(module_str, state)

      %{"topic" => "lv:event", "payload" => %{"event" => event, "params" => params}} ->
        handle_lv_event(event, params, state)

      %{"topic" => "lv:heartbeat"} ->
        {:reply, {:text, Jason.encode!(%{topic: "lv:heartbeat_ack"})}, state}

      _ ->
        {:ok, state}
    end
  end

  # Binary frames carry file upload chunks
  @impl true
  def websocket_handle({:binary, data}, state) do
    # Protocol: [2 bytes: ref_len][ref_len bytes: ref_string][rest: chunk_data]
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

  defp handle_join(module_str, state) do
    Logger.error("[Handler] handle_join for #{module_str}")
    clean_module = String.replace(module_str, ~r/^Elixir\./, "")
    view_module = String.to_existing_atom("Elixir." <> clean_module)
    session = Map.get(state, :session, %{})
    
    # Subscribe the WebSocket process to the module-specific topic if it exists
    if function_exported?(view_module, :topic, 0) do
      topic = apply(view_module, :topic, [])
      Ignite.PubSub.subscribe(topic)
    end

    # Track that this process is now "connected" (WebSocket)
    Process.put(:ignite_connected, true)

    case apply(view_module, :mount, [%{}, session]) do
      {:ok, assigns} ->
        new_rendered = Engine.render(view_module, assigns)
        {streams_payload, assigns} = Stream.extract_stream_ops(assigns)
        assigns = Ignite.LiveView.collect_components(assigns)

        normalized_rendered = Engine.normalize(new_rendered)

        new_state = %{
          mounted: true,
          view: view_module,
          assigns: assigns,
          rendered: normalized_rendered
        }

        payload_map = %{diff: Diff.calculate(nil, normalized_rendered)}
        payload_map = if streams_payload, do: Map.put(payload_map, :streams, streams_payload), else: payload_map
        
        msg = Jason.encode!(%{topic: "lv:update", payload: payload_map})
        {:reply, {:text, msg}, new_state}
    end
  end

  defp handle_lv_event(event, params, state) do
    case event do
      "__upload_validate__" ->
        %{"name" => name, "entries" => entries} = params
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

      "__upload_complete__" ->
        %{"name" => name, "ref" => ref} = params
        upload_name = String.to_atom(name)
        new_assigns = Ignite.LiveView.UploadHelpers.mark_complete(state.assigns, upload_name, ref)
        send_render_update(state, new_assigns)

      _ ->
        # Component event? format "id:event"
        case String.split(event, ":", parts: 2) do
          [id, real_event] when real_event != "" ->
            case Map.get(state.assigns, :__components__, %{}) |> Map.get(id) do
              {module, comp_assigns} ->
                case apply(module, :handle_event, [real_event, params, comp_assigns]) do
                  {:noreply, new_comp_assigns} ->
                    new_components = Map.put(state.assigns.__components__, id, {module, new_comp_assigns})
                    new_assigns = %{state.assigns | __components__: new_components}
                    send_render_update(state, new_assigns)
                end
              _ ->
                # Fallback to main LV if component not found or simple id
                handle_regular_event(event, params, state)
            end

          _ ->
            handle_regular_event(event, params, state)
        end
    end
  end

  defp handle_regular_event(event, params, state) do
    case apply(state.view, :handle_event, [event, params, state.assigns]) do
      {:noreply, new_assigns} ->
        send_render_update(state, new_assigns)
    end
  end

  # For PubSub/Broadcasting
  @impl true
  def websocket_info(msg, state) do
    Process.put(:ignite_connected, true)
    case apply(state.view, :handle_info, [msg, state.assigns]) do
      {:noreply, new_assigns} ->
        send_render_update(state, new_assigns)
    end
  end

  defp send_render_update(state, new_assigns) do
    case Map.pop(new_assigns, :__redirect__) do
      {nil, clean_assigns} ->
        clean_assigns = Ignite.LiveView.collect_components(clean_assigns)
        rendered = apply(state.view, :render, [clean_assigns])
        rendered = Engine.normalize(rendered)

        {stream_ops, clean_assigns} = Stream.extract_stream_ops(clean_assigns)
        diff = Diff.calculate(state.rendered, rendered)

        payload_map = %{diff: diff}
        payload_map = if stream_ops, do: Map.put(payload_map, :streams, stream_ops), else: payload_map
        
        payload = Jason.encode!(%{topic: "lv:update", payload: payload_map})
        {:reply, {:text, payload}, %{state | assigns: clean_assigns, rendered: rendered}}

      {redirect_info, clean_assigns} ->
        msg = Jason.encode!(%{topic: "lv:redirect", payload: redirect_info})
        {:reply, {:text, msg}, %{state | assigns: clean_assigns}}
    end
  end

  defp send_render_update_with_upload_config(state, new_assigns, upload_name) do
    new_assigns = Ignite.LiveView.collect_components(new_assigns)
    rendered = apply(state.view, :render, [new_assigns])
    rendered = Engine.normalize(rendered)
    
    {stream_ops, new_assigns} = Stream.extract_stream_ops(new_assigns)
    diff = Diff.calculate(state.rendered, rendered)
    
    upload_config = Ignite.LiveView.UploadHelpers.build_upload_config(new_assigns, upload_name)
    
    payload_map = %{diff: diff}
    payload_map = if stream_ops, do: Map.put(payload_map, :streams, stream_ops), else: payload_map
    payload_map = if upload_config, do: Map.put(payload_map, :upload, upload_config), else: payload_map
    
    payload = Jason.encode!(%{topic: "lv:update", payload: payload_map})
    {:reply, {:text, payload}, %{state | assigns: new_assigns, rendered: rendered}}
  end
end
