defmodule Ignite.LiveView.Handler do
  @behaviour :cowboy_websocket

  require Logger

  alias Ignite.LiveView.Engine

  @impl true
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  # On mount: send statics + dynamics
  @impl true
  def websocket_init(state) do
    view_module = state.view

    case apply(view_module, :mount, [%{}, %{}]) do
      {:ok, assigns} ->
        {statics, dynamics} = Engine.render(view_module, assigns)
        Logger.info("[LiveView] Mounted #{inspect(view_module)}")
        payload = Jason.encode!(%{s: statics, d: dynamics})
        {:reply, {:text, payload}, %{view: view_module, assigns: assigns}}
    end
  end

  # On event: send only dynamics
  @impl true
  def websocket_handle({:text, frame}, state) do
    case Jason.decode(frame) do
      {:ok, %{"event" => event, "params" => params}} ->
        # Route component events (format: "component_id:event_name")
        {new_assigns, is_component_event} = handle_possible_component_event(event, params, state)

        new_assigns =
          if is_component_event do
            new_assigns
          else
            case apply(state.view, :handle_event, [event, params, state.assigns]) do
              {:noreply, assigns} -> assigns
            end
          end

        # Check for pending redirect
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

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info(msg, state) do
    Logger.info("[Handler] Received process message: #{inspect(msg)}")

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

  defp send_render_update(state, assigns) do
    dynamics = Engine.render_dynamics(state.view, assigns)
    # Step 19: Collect component state set during render
    assigns = Ignite.LiveView.collect_components(assigns)
    payload = Jason.encode!(%{d: dynamics})
    {:reply, {:text, payload}, %{state | assigns: assigns}}
  end

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
end
