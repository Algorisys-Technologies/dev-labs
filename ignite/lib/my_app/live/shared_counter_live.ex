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
    """
    <div id="shared-counter">
      <h1>Shared Counter</h1>
      <p>Open in multiple tabs — clicks sync in real time via PubSub</p>
      <p style="font-size: 4em;">#{assigns.count}</p>
      <button ignite-click="decrement">-</button>
      <button ignite-click="increment">+</button>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="color: #888; font-size: 14px;">Navigate without page reload:</p>
        <a href="/" style="margin: 0 8px;">Home</a>
        <a href="/counter" ignite-navigate="/counter" style="margin: 0 8px;">Counter</a>
        <a href="/dashboard" ignite-navigate="/dashboard" style="margin: 0 8px;">Dashboard</a>
        <a href="/components" ignite-navigate="/components" style="margin: 0 8px;">Components</a>
        <a href="/hooks" ignite-navigate="/hooks" style="margin: 0 8px;">Hooks</a>
      </div>
    </div>
    """
  end
end
