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
    status = if params["success"] == "true", do: "copied ✅", else: "failed ❌"
    event = "Clipboard: #{status}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def handle_event("local_time", params, assigns) do
    event = "Client time pushed: #{params["time"]}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def render(assigns) do
    events_html = if assigns.hook_events == [] do
      "<em>No hook events yet — interaction required below...</em>"
    else
      assigns.hook_events
      |> Enum.map(fn e -> "<li style='color: #2c3e50;'>#{e}</li>" end)
      |> Enum.join("\n")
    end

    ~L"""
    <div id="hooks-demo" style="max-width: 800px; margin: 0 auto; text-align: center;">
      <h1 style="color: #2c3e50;">JS Hooks Demo</h1>
      <p style="color: #7f8c8d; font-size: 1.1em;">Bridging Elixir and JavaScript via Lifecycle Callbacks.</p>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 40px 0; text-align: left;">
        
        <!-- Clipboard Hook -->
        <div style="padding: 20px; background: #fff8f0; border: 1px solid #ffe8cc; border-radius: 8px;">
          <h3 style="margin-top: 0;">Clipboard Hook</h3>
          <p style="font-size: 0.9em; color: #d9480f;">Uses Browser Clipboard API + pushEvent.</p>
          <div id="clipboard-hook" ignite-hook="CopyToClipboard" data-text="<%= assigns.copy_text %>"
               style="display: flex; gap: 10px; flex-direction: column;">
            <code style="padding: 10px; background: #fff; border: 1px dashed #ffa94d; border-radius: 4px;"><%= assigns.copy_text %></code>
            <button id="copy-btn"
                    style="padding: 10px; background: #f08c00; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">
              Copy to Clipboard
            </button>
          </div>
        </div>

        <!-- Local Time Hook -->
        <div style="padding: 20px; background: #f0f4ff; border: 1px solid #d0ebff; border-radius: 8px;">
          <h3 style="margin-top: 0;">Local Time Hook</h3>
          <p style="font-size: 0.9em; color: #1c7ed6;">Pure client-side timer + pushEvent.</p>
          <div id="time-hook" ignite-hook="LocalTime"
               style="display: flex; gap: 10px; flex-direction: column;">
            <div id="local-time-display" style="font-size: 2em; font-weight: bold; color: #1c7ed6; text-align: center;">--:--:--</div>
            <button id="send-time-btn"
                    style="padding: 10px; background: #228be6; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">
              Push Time to Server
            </button>
          </div>
        </div>

      </div>

      <div style="margin: 40px 0; padding: 20px; background: #f3fffb; border: 1px solid #c2f3e1; border-radius: 8px; text-align: left;">
        <h3 style="margin-top: 0;">Server Log (Hook Events)</h3>
        <ul style="margin: 10px 0; min-height: 100px;">
          <%= events_html %>
        </ul>
      </div>

      <div style="margin: 40px 0; padding: 20px; background: #fff; border: 1px solid #eee; border-radius: 8px;">
         <h3 style="margin-top: 0;">Regular LiveView Event</h3>
         <p>Server clicks: <strong><%= assigns.server_clicks %></strong></p>
         <button ignite-click="server_click" style="padding: 10px 20px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">
           Click Parent
         </button>
      </div>

      <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee;">
        <a href="/components" ignite-navigate="/components" style="margin: 0 10px; color: #3498db; text-decoration: none;">&larr; Back to Components</a>
        <a href="/dashboard" ignite-navigate="/dashboard" style="margin: 0 10px; color: #3498db; text-decoration: none;">Dashboard &rarr;</a>
      </div>
    </div>
    """
  end
end
