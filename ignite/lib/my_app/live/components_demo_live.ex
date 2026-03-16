defmodule MyApp.ComponentsDemoLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    {:ok, %{clicks: 0}}
  end

  @impl true
  def handle_event("parent_click", _params, assigns) do
    {:noreply, %{assigns | clicks: assigns.clicks + 1}}
  end

  @impl true
  def render(assigns) do
    """
    <div id="components-demo">
      <h1>LiveComponents Demo</h1>
      <p>Parent clicks: <strong>#{assigns.clicks}</strong></p>
      <button ignite-click="parent_click">Click Parent</button>

      <div style="margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h3>Notification Badge (Stateful Component)</h3>
        #{live_component(assigns, MyApp.Components.NotificationBadge, id: "alerts", label: "Alerts", count: 3)}
      </div>

      <div style="margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h3>Toggle Buttons (Independent Instances)</h3>
        <div style="display: flex; gap: 10px; justify-content: center;">
          #{live_component(assigns, MyApp.Components.ToggleButton, id: "dark-mode", label: "Dark Mode")}
          #{live_component(assigns, MyApp.Components.ToggleButton, id: "notifications", label: "Enable Notifications")}
        </div>
      </div>

       <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="color: #888; font-size: 14px;">Navigate without page reload:</p>
        <a href="/" style="margin: 0 8px;">Home</a>
        <a href="/counter" ignite-navigate="/counter" style="margin: 0 8px;">Counter</a>
        <a href="/dashboard" ignite-navigate="/dashboard" style="margin: 0 8px;">Dashboard</a>
        <a href="/shared-counter" ignite-navigate="/shared-counter" style="margin: 0 8px;">Shared Counter</a>
        <a href="/hooks" ignite-navigate="/hooks" style="margin: 0 8px;">Hooks</a>
      </div>
    </div>
    """
  end
end
