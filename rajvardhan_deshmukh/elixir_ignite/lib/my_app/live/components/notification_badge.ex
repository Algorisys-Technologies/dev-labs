defmodule MyApp.Components.NotificationBadge do
  use Ignite.LiveComponent

  @impl true
  def mount(props) do
    # Initialize component state by merging defaults with props from parent
    {:ok, Map.merge(%{count: 0, label: "Notifications", dismissed: false}, props)}
  end

  @impl true
  def handle_event("dismiss", _params, assigns) do
    # Components manage their own state independent of the parent
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
      <div style="background: #f0f0f0; padding: 10px; border-radius: 5px; margin: 10px 0;">
        <span>#{assigns.label} dismissed</span>
        <button ignite-click="restore" style="margin-left: 10px;">Undo</button>
      </div>
      """
    else
      """
      <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin: 10px 0; border-left: 5px solid #2196f3;">
        <strong>#{assigns.label}: #{assigns.count}</strong>
        <button ignite-click="dismiss" style="margin-left: 10px;">Dismiss</button>
      </div>
      """
    end
  end
end
