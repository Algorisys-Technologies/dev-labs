defmodule MyApp.FEExTestLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    {:ok, %{
      name: "World",
      show_details: false,
      items: ["Ignite", "FEEx", "Resilience"],
      dangerous: "<script>alert('xss')</script>"
    }}
  end

  @impl true
  def handle_event("toggle", _params, assigns) do
    {:noreply, %{assigns | show_details: !assigns.show_details}}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div style="padding: 20px; font-family: sans-serif;">
      <h1>FEEx Test Page</h1>
      <p>Hello, <%= @name %>!</p>
      
      <p>
        <button ignite-click="toggle" style="padding: 8px 16px;">
          <%= if @show_details, do: "Hide Details", else: "Show Details" %>
        </button>
      </p>

      <%= if @show_details do %>
        <div style="background: #f0f0f0; padding: 15px; border-radius: 8px; margin-top: 10px;">
          <h3>Framework Features:</h3>
          <ul>
            <%= for item <- @items do %>
              <li><%= item %></li>
            <% end %>
          </ul>
          
          <p><strong>Auto-escaping check (should be visible text, not an alert):</strong></p>
          <div style="border: 1px solid red; padding: 5px;">
            <%= @dangerous %>
          </div>

          <p><strong>Raw HTML check (should be bold):</strong></p>
          <div>
            <%= raw("<b>This is bold</b>") %>
          </div>
        </div>
      <% end %>

      <p style="margin-top: 20px;">
        <a href="/" ignite-navigate="/" style="color: #3498db;">&larr; Back to Home</a>
      </p>
    </div>
    """
  end
end
