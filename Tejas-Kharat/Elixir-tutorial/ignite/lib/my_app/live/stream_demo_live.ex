defmodule MyApp.StreamDemoLive do
  use Ignite.LiveView

  @event_types ["info", "warning", "debug", "error"]

  @impl true
  def mount(_params, _session) do
    Process.send_after(self(), :generate_event, 2000)

    assigns = %{event_count: 0}

    # Initialize the stream with a render function and a limit of 20.
    assigns =
      stream(assigns, :events, [],
        limit: 20,
        render: fn event ->
          color = event_color(event.type)

          ~L"""
          <div id="events-<%= event.id %>"
               style="padding: 8px 12px; margin: 4px 0; background: <%= color %>;
                      border-radius: 6px; font-size: 14px; display: flex;
                      justify-content: space-between; align-items: center;">
            <span>
              <strong>[<%= String.upcase(event.type) %>]</strong> <%= event.message %>
            </span>
            <span style="color: #888; font-size: 12px;"><%= event.time %></span>
          </div>
          """
          # Note: stream's render_fn returns HTML, but we use ~L for consistency.
          # Our Stream implementation expects a string, so we'll convert it.
          # Wait, the tutorial used ~s or plain heredoc. Let's use ~L and Ignite.LiveView.Engine.render_to_string
          |> render_to_html()
        end
      )

    {:ok, assigns}
  end

  defp render_to_html(rendered) do
    # Simple helper to turn the %Rendered{} struct into a string for the WebSocket
    Enum.zip(rendered.statics, rendered.dynamics ++ [""])
    |> Enum.map(fn {s, d} -> s <> to_string(d) end)
    |> Enum.join()
  end

  # Auto-generate a random event every 2 seconds
  @impl true
  def handle_info(:generate_event, assigns) do
    Process.send_after(self(), :generate_event, 2000)
    event = random_event(assigns.event_count + 1)

    assigns =
      assigns
      |> Map.put(:event_count, assigns.event_count + 1)
      |> stream_insert(:events, event, at: 0)

    {:noreply, assigns}
  end

  @impl true
  def handle_event("add_event", _params, assigns) do
    event = %{
      id: assigns.event_count + 1,
      type: "info",
      message: "Manual event (prepended to top)",
      time: format_time()
    }

    assigns =
      assigns
      |> Map.put(:event_count, assigns.event_count + 1)
      |> stream_insert(:events, event, at: 0)

    {:noreply, assigns}
  end

  @impl true
  def handle_event("append_event", _params, assigns) do
    event = %{
      id: assigns.event_count + 1,
      type: "debug",
      message: "Manual event (appended to bottom)",
      time: format_time()
    }

    assigns =
      assigns
      |> Map.put(:event_count, assigns.event_count + 1)
      |> stream_insert(:events, event)

    {:noreply, assigns}
  end

  # Upsert: re-insert an item with the same ID — updates in-place on the client
  @impl true
  def handle_event("update_latest", _params, assigns) do
    if assigns.event_count > 0 do
      updated_event = %{
        id: assigns.event_count,
        type: "warning",
        message: "UPDATED — this event was modified in-place via upsert",
        time: format_time()
      }

      assigns = stream_insert(assigns, :events, updated_event, at: 0)
      {:noreply, assigns}
    else
      {:noreply, assigns}
    end
  end

  @impl true
  def handle_event("clear_log", _params, assigns) do
    assigns =
      assigns
      |> Map.put(:event_count, 0)
      |> stream(:events, [], reset: true)

    {:noreply, assigns}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div id="stream-demo" style="max-width: 700px; margin: 0 auto;">
      <h1>LiveView Streams Demo</h1>
      <p style="color: #888; font-size: 14px;">
        Events stream in every 2 seconds — only new items are sent over the wire
      </p>

      <div style="display: flex; gap: 12px; margin: 16px 0; align-items: center;">
        <button ignite-click="add_event"
                style="padding: 8px 16px; background: #3498db; color: white;
                       border: none; border-radius: 6px; cursor: pointer;">
          Prepend Event
        </button>
        <button ignite-click="append_event"
                style="padding: 8px 16px; background: #2ecc71; color: white;
                       border: none; border-radius: 6px; cursor: pointer;">
          Append Event
        </button>
        <button ignite-click="update_latest"
                style="padding: 8px 16px; background: #f39c12; color: white;
                       border: none; border-radius: 6px; cursor: pointer;">
          Update Latest
        </button>
        <button ignite-click="clear_log"
                style="padding: 8px 16px; background: #e74c3c; color: white;
                       border: none; border-radius: 6px; cursor: pointer;">
          Clear Log
        </button>
        <span style="color: #666; font-size: 14px;">
          Total events: <strong><%= @event_count %></strong>
        </span>
      </div>

      <div ignite-stream="events"
           style="max-height: 400px; overflow-y: auto; border: 1px solid #eee;
                  border-radius: 8px; padding: 8px;">
      </div>

      <div style="margin-top: 30px; text-align: center;">
        <a href="/" style="color: #3498db;">&larr; Back to Home</a>
      </div>
    </div>
    """
  end

  # --- Private helpers ---

  defp random_event(id) do
    type = Enum.random(@event_types)

    messages = %{
      "info" => ["System running normally", "Health check passed", "Cache refreshed"],
      "warning" => ["Memory usage high", "Response time slow", "Rate limit approaching"],
      "debug" => ["Query executed in 2ms", "Cache hit ratio: 94%", "GC cycle complete"],
      "error" => ["Connection timeout", "Invalid API key", "File not found"]
    }

    %{id: id, type: type, message: Enum.random(messages[type]), time: format_time()}
  end

  defp format_time do
    {{_, _, _}, {h, m, s}} = :calendar.local_time()
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s]) |> to_string()
  end

  defp event_color("info"), do: "#e8f4f8"
  defp event_color("warning"), do: "#fff8e1"
  defp event_color("debug"), do: "#f3e5f5"
  defp event_color("error"), do: "#ffebee"
  defp event_color(_), do: "#f5f5f5"
end
