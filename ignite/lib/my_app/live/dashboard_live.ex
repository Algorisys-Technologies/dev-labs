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
    """
    <div id="dashboard" style="max-width: 600px; margin: 0 auto;">
      <h1>BEAM Dashboard</h1>
      <p style="color: #888;">Auto-refreshes every second via handle_info</p>
      <p>Uptime: #{assigns.uptime}</p>
      <p>Processes: #{assigns.process_count}</p>
      <p>Memory: #{assigns.total_memory} MB</p>
      <button ignite-click="gc">Run GC</button>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p style="color: #888; font-size: 14px;">Navigate without page reload:</p>
        <a href="/" style="margin: 0 8px;">Home</a>
        <a href="/counter" ignite-navigate="/counter" style="margin: 0 8px;">Counter</a>
        <a href="/shared-counter" ignite-navigate="/shared-counter" style="margin: 0 8px;">Shared Counter</a>
        <a href="/components" ignite-navigate="/components" style="margin: 0 8px;">Components</a>
        <a href="/hooks" ignite-navigate="/hooks" style="margin: 0 8px;">Hooks</a>
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
