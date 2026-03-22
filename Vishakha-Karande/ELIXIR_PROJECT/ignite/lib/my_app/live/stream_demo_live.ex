defmodule MyApp.StreamDemoLive do
  use Ignite.LiveView

  @event_types ["info", "warning", "debug", "error"]

  @impl true
  def mount(_params, _session) do
    if Ignite.LiveView.connected?(self()) do
        Process.send_after(self(), :generate_event, 2000)
    end

    assigns = %{event_count: 0}

    # Initialize the stream with a render function and a limit of 20.
    assigns =
      stream(assigns, :events, [],
        limit: 20,
        render: fn event ->
          color = event_color(event.type)

          """
          <div id="events-#{event.id}"
               style="padding: 12px; margin: 8px 0; background: #{color};
                      border-radius: 8px; font-size: 14px; display: flex;
                      justify-content: space-between; align-items: center;
                      box-shadow: 0 2px 4px rgba(0,0,0,0.05); border-left: 4px solid #3366ff;">
            <span>
              <strong style="color: #444;">[#{String.upcase(event.type)}]</strong> 
              <span style="margin-left: 8px;">#{event.message}</span>
            </span>
            <span style="color: #666; font-family: monospace;">#{event.time}</span>
          </div>
          """
        end
      )

    {:ok, assigns}
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
    ~L"""
    <div id="stream-demo" style="max-width: 800px; margin: 40px auto; font-family: 'Inter', sans-serif; color: #333;">
      <h1 style="font-size: 2.5rem; font-weight: 800; margin-bottom: 8px;">LiveView Streams</h1>
      <p style="color: #666; font-size: 1.1rem; margin-bottom: 24px;">
        Efficiently managing large collections with O(1) wire overhead.
      </p>

      <div style="background: #fdfdfd; padding: 24px; border-radius: 12px; border: 1px solid #eef; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); margin-bottom: 24px;">
        <div style="display: flex; gap: 12px; margin-bottom: 20px; align-items: center; flex-wrap: wrap;">
            <button ignite-click="add_event"
                    style="padding: 10px 20px; background: #3b82f6; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.2s;">
            Prepend
            </button>
            <button ignite-click="append_event"
                    style="padding: 10px 20px; background: #10b981; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.2s;">
            Append
            </button>
            <button ignite-click="update_latest"
                    style="padding: 10px 20px; background: #f59e0b; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.2s;">
            Upsert
            </button>
            <button ignite-click="clear_log"
                    style="padding: 10px 20px; background: #ef4444; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.2s;">
            Clear
            </button>
            
            <div style="margin-left: auto; background: #eee; padding: 10px 16px; border-radius: 8px; font-weight: 700;">
            Total: <%= assigns.event_count %>
            </div>
        </div>

        <div ignite-stream="events"
            style="height: 400px; overflow-y: auto; border: 2px solid #f0f0f0; border-radius: 12px; padding: 16px; background: white;">
        </div>
      </div>

      <p style="text-align: center;">
        <a href="/" ignite-navigate="/" style="color: #6366f1; text-decoration: none; font-weight: 600;">&larr; Return Home</a>
      </p>
    </div>
    """
  end

  # --- Private helpers ---

  defp random_event(id) do
    type = Enum.random(@event_types)

    messages = %{
      "info" => ["System pulse stable", "User session validated", "Database optimization complete"],
      "warning" => ["Disk space at 85%", "Partial outage detected", "Slow query logged"],
      "debug" => ["Replicated state in 4ms", "Cache hit recorded", "Worker pool resized"],
      "error" => ["Fatal crash recovered", "Handshake failed", "Port 443 blocked"]
    }

    %{id: id, type: type, message: Enum.random(messages[type]), time: format_time()}
  end

  defp format_time do
    {{_, _, _}, {h, m, s}} = :calendar.local_time()
    :io_lib.format("~2..0B:~2..0B:~2..0B", [h, m, s]) |> to_string()
  end

  defp event_color("info"), do: "#f0f9ff"
  defp event_color("warning"), do: "#fffbeb"
  defp event_color("debug"), do: "#f5f3ff"
  defp event_color("error"), do: "#fef2f2"
  defp event_color(_), do: "#f8fafc"
end
