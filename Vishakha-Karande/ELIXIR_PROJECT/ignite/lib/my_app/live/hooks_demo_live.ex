defmodule MyApp.HooksDemoLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    {:ok, %{
      server_clicks: 0,
      hook_events: [],
      copy_text: "Hello from Ignite! Copy me to clipboard."
    }}
  end

  @impl true
  def handle_event("server_click", _params, assigns) do
    {:noreply, %{assigns | server_clicks: assigns.server_clicks + 1}}
  end

  # Receives events pushed from JS hooks via pushEvent()
  @impl true
  def handle_event("clipboard_result", params, assigns) do
    status = if params["success"] == "true", do: "copied", else: "failed"
    event = "Clipboard: #{status}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def handle_event("local_time", params, assigns) do
    event = "Client time: #{params["time"]}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div id="hooks-demo" style="max-width: 600px; margin: 0 auto;">
      <h1>JS Hooks Demo</h1>

      <div style="margin: 24px 0; padding: 20px; background: #f8f9fa; border-radius: 8px;">
        <h3 style="margin-top: 0;">Server State</h3>
        <p>Server clicks: <strong><%= assigns.server_clicks %></strong></p>
        <button ignite-click="server_click"
                style="padding: 8px 16px; background: #3498db; color: white; border: none; border-radius: 6px; cursor: pointer;">
          Server Click
        </button>
      </div>

      <div style="margin: 24px 0; padding: 20px; background: #fff8f0; border-radius: 8px;">
        <h3 style="margin-top: 0;">Clipboard Hook</h3>
        <div id="clipboard-hook" ignite-hook="CopyToClipboard" data-text="<%= assigns.copy_text %>"
             style="display: flex; gap: 12px; align-items: center;">
          <code style="padding: 8px 12px; background: #eee; border-radius: 4px; flex: 1;"><%= assigns.copy_text %></code>
          <button id="copy-btn"
                  style="padding: 8px 16px; background: #9b59b6; color: white; border: none; border-radius: 6px; cursor: pointer;">
            Copy
          </button>
        </div>
      </div>

      <div style="margin: 24px 0; padding: 20px; background: #f0f4ff; border-radius: 8px;">
        <h3 style="margin-top: 0;">Local Time Hook</h3>
        <div id="time-hook" ignite-hook="LocalTime"
             style="display: flex; gap: 12px; align-items: center;">
          <span id="local-time-display" style="font-size: 18px; font-weight: bold;">--:--:--</span>
          <button id="send-time-btn"
                  style="padding: 8px 16px; background: #27ae60; color: white; border: none; border-radius: 6px; cursor: pointer;">
            Send to Server
          </button>
        </div>
      </div>

      <div style="margin: 24px 0; padding: 20px; background: #f0fff4; border-radius: 8px;">
        <h3 style="margin-top: 0;">Hook Events Log</h3>
        <ul style="margin: 8px 0; padding-left: 20px;">
          <%= for event <- assigns.hook_events do "<li>#{event}</li>" end %>
        </ul>
      </div>
    </div>
    """
  end
end
