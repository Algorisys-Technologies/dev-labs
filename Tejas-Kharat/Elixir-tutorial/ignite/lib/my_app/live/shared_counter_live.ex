defmodule MyApp.SharedCounterLive do
  use Ignite.LiveView

  @topic "shared_counter"

  def mount(_params, _session) do
    Ignite.PubSub.subscribe(@topic)
    {:ok, %{count: 0}}
  end

  def handle_event("increment", _params, assigns) do
    new_count = assigns.count + 1
    Ignite.PubSub.broadcast(@topic, {:count_updated, new_count})
    {:noreply, %{assigns | count: new_count}}
  end

  def handle_event("decrement", _params, assigns) do
    new_count = assigns.count - 1
    Ignite.PubSub.broadcast(@topic, {:count_updated, new_count})
    {:noreply, %{assigns | count: new_count}}
  end

  def handle_info({:count_updated, count}, assigns) do
    {:noreply, %{assigns | count: count}}
  end

  def render(assigns) do
    ~L"""
    <div id="shared-counter">
      <h1>Shared Counter</h1>
      <p>Open in multiple tabs — clicks sync in real time via PubSub</p>
      <p style="font-size: 4em;"><%= assigns.count %></p>
      <button ignite-click="decrement">-</button>
      <button ignite-click="increment">+</button>
    </div>
    """
  end
end
