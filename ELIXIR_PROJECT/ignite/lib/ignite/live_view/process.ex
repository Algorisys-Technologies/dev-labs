defmodule Ignite.LiveView.Process do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # --- Callbacks ---

  @impl true
  def init(opts) do
    module = Keyword.fetch!(opts, :module)
    params = Keyword.get(opts, :params, %{})
    session = Keyword.get(opts, :session, %{})
    socket_pid = Keyword.get(opts, :socket_pid)

    # 1. Mount the LiveView
    case module.mount(params, session) do
      {:ok, assigns} ->
        # 2. Initial render
        rendered = module.render(assigns)
        
        state = %{
          module: module,
          assigns: assigns,
          socket_pid: socket_pid,
          last_rendered: rendered
        }
        {:ok, state}
    end
  end

  @impl true
  def handle_cast({:event, event_name, params}, state) do
    # 3. Route component events (format: "component_id:event_name")
    {new_assigns, is_component_event} = handle_possible_component_event(event_name, params, state)

    new_assigns =
      if is_component_event do
        new_assigns
      else
        case state.module.handle_event(event_name, params, state.assigns) do
          {:noreply, assigns} -> assigns
        end
      end

    process_update(state, new_assigns)
  end

  defp handle_possible_component_event(event, params, state) do
    case String.split(event, ":", parts: 2) do
      [component_id, component_event] ->
        components = Map.get(state.assigns, :__components__, %{})

        case Map.get(components, component_id) do
          {module, comp_assigns} ->
            {:noreply, updated_comp_assigns} =
              apply(module, :handle_event, [component_event, params, comp_assigns])

            new_components = Map.put(components, component_id, {module, updated_comp_assigns})
            {Map.put(state.assigns, :__components__, new_components), true}

          nil ->
            {state.assigns, false}
        end

      _ ->
        {state.assigns, false}
    end
  end

  @impl true
  def handle_info(msg, state) do
    # handle_info from PubSub or other sources
    case state.module.handle_info(msg, state.assigns) do
      {:noreply, new_assigns} ->
        process_update(state, new_assigns)
    end
  end

  defp process_update(state, new_assigns) do
    case Map.pop(new_assigns, :__redirect__) do
      {nil, assigns} ->
        # 1. Render and Diff
        new_rendered = state.module.render(assigns)
        
        # 2. Collect any components that were rendered and update assigns
        assigns = Ignite.LiveView.collect_components(assigns)
        
        diff = Ignite.LiveView.Diff.calculate(state.last_rendered, new_rendered)

        new_state = %{state | 
          assigns: assigns,
          last_rendered: new_rendered
        }
        
        # 2. Push the diff back to the JS
        push_diff(new_state, diff)
        {:noreply, new_state}

      {redirect_info, assigns} ->
        # 1. Push the redirect to the JS
        push_redirect_to_client(state, redirect_info)
        
        # 2. Keep the state updated but wait for the client to reconnect elsewhere
        {:noreply, %{state | assigns: assigns}}
    end
  end

  defp push_diff(state, diff) do
    if state.socket_pid do
      msg = Jason.encode!(%{topic: "lv:update", payload: %{diff: diff}})
      send(state.socket_pid, {:render, msg}) # The server will handle raw binary send
    end
  end

  defp push_redirect_to_client(state, info) do
    if state.socket_pid do
      msg = Jason.encode!(%{topic: "lv:redirect", payload: info})
      send(state.socket_pid, {:render, msg})
    end
  end
end
