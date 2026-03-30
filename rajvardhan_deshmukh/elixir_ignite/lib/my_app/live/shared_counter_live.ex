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
      <h2><%= assigns.count %></h2>

      <div>
        <button ignite-click="decrement">-</button>
        <button ignite-click="increment">+</button>
      </div>

      <!-- Navigation Links -->
      <div style="margin-top: 30px; font-size: 0.9em;">
        <h4>Navigation</h4>
        <a href="/counter" ignite-navigate="/counter">Counter</a> | 
        <a href="/dashboard" ignite-navigate="/dashboard">Dashboard</a> | 
        <a href="/shared-counter" ignite-navigate="/shared-counter">Shared Counter</a>
      </div>
    </div>
    """
  end
end
