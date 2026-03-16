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
      <span>#{assigns.label} dismissed</span>
      <button ignite-click="restore">Undo</button>
      """
    else
      """
      <span>#{assigns.label}: #{assigns.count}</span>
      <button ignite-click="dismiss">Dismiss</button>
      """
    end
  end
end
