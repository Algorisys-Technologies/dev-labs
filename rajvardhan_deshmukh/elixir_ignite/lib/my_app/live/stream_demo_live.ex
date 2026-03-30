defmodule MyApp.StreamDemoLive do
  @moduledoc """
  Step 25: Streams Demo.
  Demonstrates efficient O(1) list updates for an activity log.
  """
  use Ignite.LiveView

  def mount(_params, _session) do
    # Auto-generate events every 2 seconds
    if connected?(), do: Process.send_after(self(), :generate_event, 2000)

    # Initialize the stream
    assigns = %{event_count: 0}
    assigns = stream(assigns, :events, [],
      limit: 20,
      render: fn event ->
        ~s(<div id="events-#{event.id}" style="padding: 10px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center;">
             <span>[#{event.id}] <strong>#{event.type}</strong>: #{event.message}</span>
             <button ignite-click="remove_event" ignite-value="#{event.id}" style="padding: 2px 5px; font-size: 0.8em;">&times;</button>
           </div>)
      end
    )
    {:ok, assigns}
  end

  def handle_event("update_latest", _params, assigns) do
    if assigns.event_count > 0 do
      updated_event = %{
        id: assigns.event_count,
        type: "WARNING",
        message: "UPDATED — this event was modified in-place via upsert"
      }
      assigns = stream_insert(assigns, :events, updated_event, at: 0)
      {:noreply, assigns}
    else
      {:noreply, assigns}
    end
  end

  def handle_event("remove_event", %{"value" => id}, assigns) do
    # We only need the ID to delete from the stream
    assigns = stream_delete(assigns, :events, %{id: id})
    {:noreply, assigns}
  end

  def handle_event("clear_log", _params, assigns) do
    assigns = 
      assigns
      |> Map.put(:event_count, 0)
      |> stream(:events, [], reset: true)
    
    {:noreply, assigns}
  end

  def handle_info(:generate_event, assigns) do
    Process.send_after(self(), :generate_event, 2000)
    
    new_id = assigns.event_count + 1
    event = %{id: new_id, type: "INFO", message: "System activity logged at #{Time.truncate(Time.utc_now(), :second)}"}

    assigns = 
      assigns
      |> Map.put(:event_count, new_id)
      |> stream_insert(:events, event, at: 0) # Prepend newest to top

    {:noreply, assigns}
  end

  def render(assigns) do
    ~L"""
    <div id="streams-demo" style="max-width: 600px; margin: 0 auto; font-family: sans-serif;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
      <div style="display: flex; gap: 10px; border-bottom: 1px solid #eee; padding-bottom: 15px; margin-bottom: 15px;">
        <button ignite-click="clear_log" style="background: #f44; color: white; border: none; padding: 10px; border-radius: 4px; cursor: pointer;">
          Clear Log
        </button>
        <button ignite-click="update_latest" style="background: #f39c12; color: white; border: none; padding: 10px; border-radius: 4px; cursor: pointer;">
          Update Latest
        </button>
      </div>

      <p style="color: #666; display: flex; justify-content: space-between;">
        <span>Total events logged: <strong><%= assigns.event_count %></strong></span>
        <span>Limit: <strong>20 items</strong></span>
      </p>

      <div ignite-stream="events" 
           style="border: 1px solid #ccc; border-radius: 8px; min-height: 200px; max-height: 400px; overflow-y: auto; background: #fafafa;">
        <!-- Stream items will be injected here surgically -->
      </div>

      <div style="margin-top: 30px; font-size: 0.9em; border-top: 1px solid #eee; padding-top: 20px;">
        <h4>Navigation</h4>
        <a href="/counter" ignite-navigate="/counter">Counter</a> |
        <a href="/dashboard" ignite-navigate="/dashboard">Dashboard</a> |
        <a href="/streams" ignite-navigate="/streams">Streams Demo</a>
      </div>
    </div>
    """
  end

  # Simplified connected? check for our custom Ignite implementation
  defp connected? do
    Process.get(:__ignite_connected__, false)
  end
end
