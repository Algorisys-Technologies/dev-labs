defmodule MyApp.ComponentsDemoLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    {:ok, %{clicks: 0}}
  end

  @impl true
  def handle_event("parent_click", _params, assigns) do
    # Events from the parent LiveView 
    {:noreply, %{assigns | clicks: assigns.clicks + 1}}
  end

  @impl true
  def render(assigns) do
    """
    <div id="demo-page" style="text-align: left; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
      <h1>Live Components Demo</h1>
      
      <div style="background: #fff9c4; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
        <h3>Parent LiveView</h3>
        <p>Clicks tracked in parent state: <strong>#{assigns.clicks}</strong></p>
        <button ignite-click="parent_click">Click Parent</button>
      </div>

      <hr>

      <h3>Stateful Components</h3>
      <p>The components below manage their own internal state (dismissals, toggles) without the parent knowing or needing to handle those events.</p>

      #{live_component(assigns, MyApp.Components.NotificationBadge, 
          id: "alerts", label: "System Alerts", count: 3)}

      #{live_component(assigns, MyApp.Components.NotificationBadge, 
          id: "messages", label: "New Messages", count: 12)}

      <div style="margin-top: 20px; padding: 10px; border: 1px dashed #bbb;">
        <h4>Settings (Toggles)</h4>
        #{live_component(assigns, MyApp.Components.ToggleButton, 
            id: "dark-mode", label: "Dark Mode")}

        #{live_component(assigns, MyApp.Components.ToggleButton, 
            id: "notifications", label: "Enable Push")}
      </div>

      <div style="margin-top: 30px; font-size: 0.9em;">
        <h4>Navigation</h4>
        <a href="/counter" ignite-navigate="/counter">Back to Counter</a>
      </div>
    </div>
    """
  end
end
