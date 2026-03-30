defmodule MyApp.DashboardLive do
  use Ignite.LiveView

  def mount(_params, _session) do
    Process.send_after(self(), :tick, 1000)
    {:ok, gather_stats()}
  end

  def handle_info(:tick, _assigns) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, gather_stats()}
  end

  def handle_event("gc", _params, assigns) do
    :erlang.garbage_collect()
    {:noreply, assigns}
  end

  def render(assigns) do
    ~L"""
    <div id="dashboard" style="max-width: 600px; margin: 0 auto;">
      <h1>BEAM Dashboard</h1>
      <p style="color: #888;">Auto-refreshes every second via handle_info</p>
      <p>Uptime: <%= assigns.uptime %></p>
      <p>Processes: <%= assigns.process_count %></p>
      <p>Memory: <%= assigns.total_memory %> MB</p>
      <button ignite-click="gc">Run GC</button>

      <!-- Navigation Links -->
      <div style="margin-top: 30px; font-size: 0.9em;">
        <h4>Navigation</h4>
        <a href="/counter" ignite-navigate="/counter">Counter</a> |
        <a href="/dashboard" ignite-navigate="/dashboard">Dashboard</a> |
        <a href="/shared-counter" ignite-navigate="/shared-counter">Shared Counter</a>
      </div>
    </div>
    """
  end

  defp gather_stats do
    memory = :erlang.memory()
    {uptime_ms, _} = :erlang.statistics(:wall_clock)

    %{
      uptime: format_uptime(uptime_ms),
      process_count: :erlang.system_info(:process_count),
      total_memory: Float.round(memory[:total] / 1_048_576, 1)
    }
  end

  defp format_uptime(ms) do
    total_seconds = div(ms, 1000)
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m #{seconds}s"
      minutes > 0 -> "#{minutes}m #{seconds}s"
      true -> "#{seconds}s"
    end
  end
end
