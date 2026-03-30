defmodule Ignite.LiveView.Handler do
  @moduledoc """
  Cowboy WebSocket handler for LiveView connections.

  Uses the diffing engine to send statics only once (on mount) and
  only dynamics on subsequent updates.
  """

  @behaviour :cowboy_websocket

  alias Ignite.LiveView.Engine

  require Logger

  @impl true
  def init(req, state) do
    # Parse session from the WebSocket upgrade request's cookies
    cookie_header = :cowboy_req.header("cookie", req, "")
    cookies = Ignite.Session.parse_cookies(cookie_header)

    session =
      case Ignite.Session.decode(Map.get(cookies, Ignite.Session.cookie_name())) do
        {:ok, data} -> data
        :error -> %{}
      end

    {:cowboy_websocket, req, Map.put(state, :session, session)}
  end

  # On mount: send both statics and dynamics
  @impl true
  def websocket_init(state) do
    # Flag this process as "connected" for the LiveView module
    Process.put(:__ignite_connected__, true)
    
    view_module = state.view
    session = Map.get(state, :session, %{})

    case apply(view_module, :mount, [%{}, session]) do
      {:ok, initial_assigns} ->
        # We render first to "boot" any components that are called in the template
        _ = Engine.render(view_module, initial_assigns)
        
        # Then we collect their initial state from the process dictionary
        assigns = Ignite.LiveView.collect_components(initial_assigns)
        
        {statics, dynamics} = Engine.render(view_module, assigns)
        
        # Pull stream operations
        {stream_payload, final_assigns} = extract_stream_payload(assigns)
        
        Logger.info("[LiveView] Mounted #{inspect(view_module)}")

        new_state = %{view: view_module, assigns: final_assigns, dynamics: dynamics}
        
        resp = %{s: statics, d: dynamics}
        resp = if map_size(stream_payload) > 0, do: Map.put(resp, :streams, stream_payload), else: resp
        
        {:reply, {:text, Jason.encode!(resp)}, new_state}
    end
  end

  @impl true
  def websocket_handle({:text, json}, state) do
    case Jason.decode(json) do
      {:ok, %{"event" => "__upload_validate__", "params" => params}} ->
        # Handle internal upload validation
        new_assigns = handle_upload_validate(params, state.assigns)
        process_render_result(new_assigns, state)

      {:ok, %{"event" => "__upload_complete__", "params" => params}} ->
        # Handle internal upload completion
        new_assigns = handle_upload_complete(params, state.assigns)
        process_render_result(new_assigns, state)

      {:ok, %{"event" => event, "params" => params}} ->
        # 1. Try to handle it as a component event first
        {assigns_after_component, handled?} = handle_possible_component_event(event, params, state)

        if handled? do
          # Already handled by a component.
          # Re-render parent to pick up component changes
          _ = Engine.render_dynamics(state.view, assigns_after_component)

          # Collect and save component state
          final_assigns = Ignite.LiveView.collect_components(assigns_after_component)

          process_render_result(final_assigns, state)
        else
          # Not a component event. Route to parent LiveView.
          case apply(state.view, :handle_event, [event, params, state.assigns]) do
            {:noreply, new_assigns} ->
              # Re-render (this might update component state/props)
              _ = Engine.render_dynamics(state.view, new_assigns)

              # Collect and save component state
              final_assigns = Ignite.LiveView.collect_components(new_assigns)

              process_render_result(final_assigns, state)
          end
        end

      _ ->
        {:ok, state}
    end
  end

  @impl true
  def websocket_handle({:binary, data}, state) do
    # Binary frame format: <<ref_len::16, ref::binary-size(ref_len), chunk_data::binary>>
    case data do
      <<ref_len::16, ref::binary-size(ref_len), chunk::binary>> ->
        new_assigns = handle_binary_chunk(ref, chunk, state.assigns)
        # Re-render to pick up progress changes
        process_render_result(new_assigns, state)

      _ ->
        {:ok, state}
    end
  end

  @impl true
  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  @impl true
  def websocket_info(msg, state) do
    if function_exported?(state.view, :handle_info, 2) do
      case apply(state.view, :handle_info, [msg, state.assigns]) do
        {:noreply, new_assigns} ->
          # Re-render (this might update component props from parent state)
          _ = Engine.render_dynamics(state.view, new_assigns)
          
          # Collect and save component state
          final_assigns = Ignite.LiveView.collect_components(new_assigns)
          
          process_render_result(final_assigns, state)

        _ ->
          {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  # --- Helper to route namespaced events (id:event) to components ---
  defp handle_possible_component_event(event, params, state) do
    case String.split(event, ":", parts: 2) do
      [component_id, component_event] ->
        components = Map.get(state.assigns, :__components__, %{})

        case Map.get(components, component_id) do
          {module, comp_assigns} ->
            {:noreply, new_comp_assigns} =
              apply(module, :handle_event, [component_event, params, comp_assigns])

            # Update component state in the parent assigns
            new_components = Map.put(components, component_id, {module, new_comp_assigns})
            {Map.put(state.assigns, :__components__, new_components), true}

          nil ->
            {state.assigns, false}
        end

      _ ->
        {state.assigns, false}
    end
  end

  # --- Helper to process the final assigns and send updates/redirects ---
  defp process_render_result(new_assigns, state) do
    case Map.pop(new_assigns, :__redirect__) do
      {nil, final_assigns} ->
        # Get NEW dynamics
        new_dynamics = Engine.render_dynamics(state.view, final_assigns)
        
        # Pull stream operations
        {stream_payload, final_assigns_with_clean_streams} = extract_stream_payload(final_assigns)

        # Pull OLD dynamics from state if possible (requires storing them in state)
        old_dynamics = Map.get(state, :dynamics, [])
        
        # Calculate diff
        case diff_dynamics(old_dynamics, new_dynamics) do
          :no_change when map_size(stream_payload) == 0 ->
            {:ok, %{state | assigns: final_assigns_with_clean_streams}}
            
          diff ->
            new_state = %{state | assigns: final_assigns_with_clean_streams, dynamics: new_dynamics}
            
            resp = %{d: diff}
            resp = if map_size(stream_payload) > 0, do: Map.put(resp, :streams, stream_payload), else: resp
            
            # If we just had a validation event, send the upload config/entries back
            resp = 
              case Process.get(:__ignite_upload_validated__) do
                nil -> resp
                entry_data -> 
                  Process.delete(:__ignite_upload_validated__)
                  Map.put(resp, :upload, entry_data)
              end

            {:reply, {:text, Jason.encode!(resp)}, new_state}
        end

      {redirect_info, final_assigns} ->
        new_state = %{state | assigns: final_assigns}
        payload = Jason.encode!(%{redirect: redirect_info})
        {:reply, {:text, payload}, new_state}
    end
  end

  # --- Stream Helpers ---
  defp extract_stream_payload(assigns) do
    case Map.get(assigns, :__streams__, %{}) do
      streams when map_size(streams) == 0 ->
        {%{}, assigns}

      streams ->
        {payload, updated_streams} = 
          Enum.reduce(streams, {%{}, %{}}, fn {name, stream}, {payload_acc, streams_acc} ->
            {ops, updated_stream} = Ignite.LiveView.Stream.extract_ops(stream)
            
            new_payload = if map_size(ops) > 0, do: Map.put(payload_acc, name, ops), else: payload_acc
            new_streams = Map.put(streams_acc, name, updated_stream)
            
            {new_payload, new_streams}
          end)

        {payload, Map.put(assigns, :__streams__, updated_streams)}
    end
  end

  # --- Diffing Engine ---

  # Helper to find which internal values in the list changed
  defp diff_dynamics(old, new) when old == new, do: :no_change

  defp diff_dynamics(old, new) do
    changes =
      old
      |> Enum.zip(new)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{o, n}, i}, acc ->
        if o == n, do: acc, else: Map.put(acc, Integer.to_string(i), n)
      end)

    # If everything changed, just send the full array (more compact)
    if map_size(changes) == length(new) do
      new
    else
      changes
    end
  end

  # --- Upload Internal Handlers ---

  defp handle_upload_validate(%{"name" => name_str, "entries" => entries}, assigns) do
    name = String.to_existing_atom(name_str)
    uploads = Map.get(assigns, :__uploads__, %{})
    config = Map.fetch!(uploads, name)

    new_entries = Enum.map(entries, fn entry ->
      %Ignite.LiveView.UploadEntry{
        ref: entry["ref"],
        client_name: entry["name"],
        client_type: entry["type"],
        client_size: entry["size"],
        tmp_path: build_tmp_path(),
        valid?: validate_entry(entry, config)
      }
    end)

    # Signal to process_render_result that we need to send back the metadata
    Process.put(:__ignite_upload_validated__, %{
      name: name,
      chunk_size: config.chunk_size,
      auto_upload: config.auto_upload,
      entries: Enum.map(new_entries, & %{ref: &1.ref, valid: &1.valid?, errors: &1.errors})
    })

    updated_config = %{config | entries: config.entries ++ new_entries}
    Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_config))
  end

  defp handle_binary_chunk(ref, data, assigns) do
    uploads = Map.get(assigns, :__uploads__, %{})
    
    # Find the entry across all uploads
    {entry_name_atom, entry} = find_entry_by_ref(uploads, ref)
    config = Map.get(uploads, entry_name_atom)

    # Append data to temp file
    File.write!(entry.tmp_path, data, [:append, :binary])

    # Update progress
    file_size = File.stat!(entry.tmp_path).size
    progress = min(round((file_size / entry.client_size) * 100), 100)
    updated_entry = %{entry | progress: progress}

    # Save back
    new_entries = Enum.map(config.entries, fn e -> if e.ref == ref, do: updated_entry, else: e end)
    updated_config = %{config | entries: new_entries}
    Map.put(assigns, :__uploads__, Map.put(uploads, entry_name_atom, updated_config))
  end

  defp handle_upload_complete(%{"name" => name_str, "ref" => ref}, assigns) do
    name = String.to_existing_atom(name_str)
    uploads = Map.get(assigns, :__uploads__, %{})
    config = Map.fetch!(uploads, name)
    
    new_entries = Enum.map(config.entries, fn e -> 
      if e.ref == ref, do: %{e | done?: true, progress: 100}, else: e 
    end)

    updated_config = %{config | entries: new_entries}
    Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_config))
  end

  defp find_entry_by_ref(uploads, ref) do
    Enum.find_value(uploads, fn {name, config} ->
      if entry = Enum.find(config.entries, & &1.ref == ref), do: {name, entry}
    end)
  end

  defp build_tmp_path do
    tmp_dir = Path.join(System.tmp_dir!(), "ignite-uploads")
    File.mkdir_p!(tmp_dir)
    Path.join(tmp_dir, "lv-upload-#{:erlang.unique_integer([:positive])}")
  end

  defp validate_entry(entry, config) do
    # Simple size validation
    entry["size"] <= config.max_file_size
    # Could add type validation here
  end
end
