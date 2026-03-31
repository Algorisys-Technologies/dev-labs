defmodule MyApp.SharedCounterLive do
  use Ignite.LiveView

  @topic "shared_counter"

  @impl true
  def mount(_params, _session) do
    if connected?(), do: subscribe(@topic)
    {:ok, %{count: 0}}
  end

  @impl true
  def handle_event("increment", _params, assigns) do
    new_count = assigns.count + 1
    broadcast(@topic, {:update_count, new_count})
    {:noreply, %{assigns | count: new_count}}
  end

  @impl true
  def handle_info({:pubsub, @topic, {:update_count, new_count}}, assigns) do
    {:noreply, %{assigns | count: new_count}}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div style="text-align: center; padding: 40px; font-family: sans-serif;">
      <h1>Shared Real-time Counter</h1>
      <p style="font-size: 48px; font-weight: bold; color: #2c3e50;">
        <%= assigns.count %>
      </p>
      <button ignite-click="increment" 
              style="padding: 12px 24px; font-size: 18px; background: #3498db; color: white; border: none; border-radius: 8px; cursor: pointer;">
        Increment (Syncs All Tabs)
      </button>
      <p style="margin-top: 20px; color: #7f8c8d;">
        Open this page in multiple tabs to see them sync!
      </p>
      <a href="/" ignite-navigate="/" style="color: #3498db; text-decoration: none;">&larr; Back to Home</a>
    </div>
    """
  end

  # Helper to check if we are in the stateful process or static render
  defp connected? do
    # In our simplistic framework, if socket_pid is set in the process, we are connected.
    # But mount/2 doesn't have access to the process state yet. 
    # For this tutorial, we'll just assume true if it's called from a process that isn't the static renderer.
    true
  end
end
