defmodule MyApp.ComponentsDemoLive do
  use Ignite.LiveView

  alias MyApp.Components.NotificationBadge
  alias MyApp.Components.ToggleButton

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
    <div style="max-width: 800px; margin: 0 auto; text-align: center;">
      <h1 style="color: #2c3e50;">LiveComponents Demo</h1>
      <p style="color: #7f8c8d; font-size: 1.1em;">Stateful, reusable widgets for Ignite.</p>

      <div style="margin: 40px 0; padding: 20px; background: #fff; border: 1px solid #eee; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
        <h2 style="margin-top: 0;">Parent State</h2>
        <p style="font-size: 2em; margin: 10px 0;">Clicks: <strong>#{assigns.clicks}</strong></p>
        <button ignite-click="parent_click" style="padding: 10px 20px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">
          Click Parent
        </button>
      </div>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 40px 0;">
        <div style="padding: 20px; border: 1px solid #eee; border-radius: 8px;">
          <h3>Notifications</h3>
          #{live_component(assigns, NotificationBadge, id: "alerts", label: "Alerts", count: 3)}
          <div style="margin-top: 20px;">
             #{live_component(assigns, NotificationBadge, id: "messages", label: "Messages", count: 12)}
          </div>
        </div>

        <div style="padding: 20px; border: 1px solid #eee; border-radius: 8px;">
          <h3>Toggle Switches</h3>
          <div style="margin-bottom: 15px;">
            #{live_component(assigns, ToggleButton, id: "dark-mode", label: "Dark Mode")}
          </div>
          <div>
            #{live_component(assigns, ToggleButton, id: "auto-save", label: "Auto Save")}
          </div>
        </div>
      </div>

      <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
        <a href="/counter" ignite-navigate="/counter" style="margin: 0 10px; color: #3498db; text-decoration: none;">&larr; Back to Counter</a>
        <a href="/dashboard" ignite-navigate="/dashboard" style="margin: 0 10px; color: #3498db; text-decoration: none;">Dashboard &rarr;</a>
      </div>
    </div>
    """
  end
end
