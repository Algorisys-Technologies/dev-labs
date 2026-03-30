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
    status = if assigns.on, do: "ON", else: "OFF"
    bg_color = if assigns.on, do: "#4caf50", else: "#ccc"
    
    """
    <div style="display: flex; align-items: center; gap: 10px; margin: 10px 0;">
      <span>#{assigns.label}:</span>
      <button ignite-click="toggle" 
              style="background: #{bg_color}; color: white; border: none; padding: 5px 15px; border-radius: 20px; transition: 0.3s;">
        #{status}
      </button>
    </div>
    """
  end
end
