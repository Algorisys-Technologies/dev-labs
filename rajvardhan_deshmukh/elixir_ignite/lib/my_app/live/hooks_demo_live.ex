defmodule MyApp.HooksDemoLive do
  @moduledoc """
  Demonstrates JS Hooks — client-side lifecycle callbacks for
  integrating third-party JavaScript with LiveView.
  """

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
    timestamp = DateTime.utc_now() |> DateTime.to_time() |> Time.truncate(:second)
    event = "[#{timestamp}] Clipboard: #{status}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def handle_event("local_time", params, assigns) do
    timestamp = DateTime.utc_now() |> DateTime.to_time() |> Time.truncate(:second)
    event = "[#{timestamp}] Client time received: #{params["time"]}"
    {:noreply, %{assigns | hook_events: [event | Enum.take(assigns.hook_events, 4)]}}
  end

  @impl true
  def render(assigns) do
    events_html = if assigns.hook_events == [] do
      "<em>No hook events yet — interaction with elements to trigger pushEvent()</em>"
    else
      """
      <ul style="list-style: none; padding: 0; font-family: monospace; font-size: 0.9em; background: #eee; padding: 10px; border-radius: 5px;">
        #{assigns.hook_events |> Enum.map(fn e -> "<li>#{e}</li>" end) |> Enum.join("")}
      </ul>
      """
    end

    """
    <div id="hooks-demo" style="max-width: 600px; margin: 0 auto; padding: 20px;">
      <h1>JS Hooks Demo</h1>
      <p>This page demonstrates client-side JS interop using lifecycle hooks.</p>

      <section style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
        <h3>1. Clipboard Hook (CopyToClipboard)</h3>
        <p>Uses the browser's <code>navigator.clipboard</code> API. Reports success back to the server.</p>
        
        <div id="clipboard-box" ignite-hook="CopyToClipboard" data-text="#{assigns.copy_text}" 
             style="display: flex; gap: 10px; align-items: center; border: 1px solid #90caf9; padding: 10px; border-radius: 4px;">
          <code style="flex-grow: 1;">#{assigns.copy_text}</code>
          <button id="copy-btn">Copy</button>
        </div>
      </section>

      <section style="background: #f1f8e9; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
        <h3>2. Local Time Hook (LocalTime)</h3>
        <p>This clock updates <strong>every second</strong> purely on the client via <code>setInterval</code>. The server doesn't even know it's ticking!</p>
        
        <div id="time-hook-container" ignite-hook="LocalTime" 
             style="display: flex; flex-direction: column; gap: 10px; border: 1px solid #a5d6a7; padding: 10px; border-radius: 4px;">
          <div>Local Time: <strong id="local-time-display">Loading...</strong></div>
          <button id="send-time-btn">Send Time to Server</button>
        </div>
      </section>

      <section style="background: #fff3e0; padding: 15px; border-radius: 8px;">
        <h3>3. Server Event Log</h3>
        <p>These messages are received by the server via <code>pushEvent()</code> in the JS Hooks.</p>
        #{events_html}
      </section>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
        <p>Server Clicks: <strong>#{assigns.server_clicks}</strong></p>
        <button ignite-click="server_click">Generic Server Click</button>
      </div>

      <div style="margin-top: 20px;">
        <a href="/components" ignite-navigate="/components">Back to Components</a>
      </div>
    </div>
    """
  end
end
