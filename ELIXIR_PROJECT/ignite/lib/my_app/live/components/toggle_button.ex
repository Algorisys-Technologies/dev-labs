defmodule MyApp.Components.ToggleButton do
  use Ignite.LiveComponent

  @impl true
  def mount(props) do
    {:ok, Map.merge(%{on: false, label: "Toggle"}, props)}
  end

  @impl true
  def handle_event("toggle", _params, assigns) do
    {:noreply, %{assigns | on: !assigns.on}}
  end

  @impl true
  def render(assigns) do
    {bg, text} =
      if assigns.on,
        do: {"#27ae60", "ON"},
        else: {"#95a5a6", "OFF"}

    ~L"""
    <div style="margin: 10px 0;">
      <button ignite-click="toggle"
              style="padding: 8px 16px; background: <%= bg %>; color: white; border: none; border-radius: 6px; cursor: pointer; transition: background 0.2s;">
        <%= assigns.label %>: <%= text %>
      </button>
    </div>
    """
  end
end
