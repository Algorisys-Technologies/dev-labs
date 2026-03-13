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
  def websocket_handle({:text, json}, state) do
    case Jason.decode!(json) do
      %{"event" => event, "params" => params} ->
        case apply(state.view, :handle_event, [event, params, state.assigns]) do
          {:noreply, new_assigns} ->
            dynamics = Engine.render_dynamics(state.view, new_assigns)
            payload = Jason.encode!(%{d: dynamics})
            {:reply, {:text, payload}, %{state | assigns: new_assigns}}
        end
    end
  end

  @impl true
  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info(_msg, state), do: {:ok, state}
end
