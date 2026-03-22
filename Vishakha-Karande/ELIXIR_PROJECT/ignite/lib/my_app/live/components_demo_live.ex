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
    ~L"""
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: sans-serif;">
      <h1>LiveComponents Demo</h1>
      
      <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
        <h3>Parent State</h3>
        <p>Parent clicks: <strong><%= assigns.clicks %></strong></p>
        <button ignite-click="parent_click" style="padding: 10px 20px; background: #3498db; color: white; border: none; border-radius: 6px; cursor: pointer;">
          Click Parent
        </button>
      </div>

      <div style="background: #fff; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h3>Embedded Components</h3>
        
        <%= live_component(assigns, MyApp.Components.NotificationBadge,
            id: "alerts", label: "System Alerts", count: 3) %>

        <%= live_component(assigns, MyApp.Components.ToggleButton,
            id: "dark-mode", label: "Dark Mode") %>
            
        <%= live_component(assigns, MyApp.Components.ToggleButton,
            id: "notifications", label: "Enable Notifications", on: true) %>
      </div>

      <p style="margin-top: 30px;">
        <a href="/" ignite-navigate="/" style="color: #3498db; text-decoration: none;">&larr; Back to Home</a>
      </p>
    </div>
    """
  end
end
