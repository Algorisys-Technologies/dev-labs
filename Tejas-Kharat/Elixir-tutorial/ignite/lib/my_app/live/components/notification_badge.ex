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
      """
      <div style="padding: 10px; background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px; display: inline-block;">
        <span>#{assigns.label} dismissed</span>
        <button ignite-click="restore" style="margin-left: 10px;">Undo</button>
      </div>
      """
    else
      """
      <div style="padding: 10px; background: #e3f2fd; border: 1px solid #90caf9; border-radius: 4px; display: inline-block;">
        <span>#{assigns.label}: <strong>#{assigns.count}</strong></span>
        <button ignite-click="dismiss" style="margin-left: 10px;">Dismiss</button>
      </div>
      """
    end
  end
end
