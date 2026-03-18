defmodule MyApp.Components.NotificationBadge do
  use Ignite.LiveComponent

  @impl true
  def mount(props) do
    {:ok, Map.merge(%{count: 0, label: "Notifications", dismissed: false}, props)}
  end

  @impl true
  def handle_event("dismiss", _params, assigns) do
    {:noreply, %{assigns | dismissed: true, count: 0}}
  end

  @impl true
  def handle_event("restore", _params, assigns) do
    {:noreply, %{assigns | dismissed: false}}
  end

  @impl true
  def render(assigns) do
    if assigns.dismissed do
      ~L"""
      <div style="background: #eee; padding: 10px; border-radius: 4px; margin: 10px 0;">
        <span><%= assigns.label %> dismissed</span>
        <button ignite-click="restore" style="margin-left: 10px;">Undo</button>
      </div>
      """
    else
      ~L"""
      <div style="background: #fff3cd; padding: 10px; border-radius: 4px; border: 1px solid #ffeeba; margin: 10px 0;">
        <span><%= assigns.label %>: <strong><%= assigns.count %></strong></span>
        <button ignite-click="dismiss" style="margin-left: 10px; background: #ffc107; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer;">Dismiss</button>
      </div>
      """
    end
  end
end
