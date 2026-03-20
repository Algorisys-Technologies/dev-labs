defmodule Ignite.RateLimiter do
  @moduledoc """
  ETS-based sliding window rate limiter.
  """
  use GenServer
  require Logger

  @table :ignite_rate_limiter
  @default_max 100
  @default_window_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Main entry point for the rate limit plug.
  """
  def call(conn) do
    config = Application.get_env(:ignite, :rate_limit, [])
    max_requests = Keyword.get(config, :max_requests, @default_max)
    window_ms = Keyword.get(config, :window_ms, @default_window_ms)

    ip = client_ip(conn)
    now = System.monotonic_time(:millisecond)

    # Record request
    :ets.insert(@table, {ip, now})

    # Count in current window
    cutoff = now - window_ms
    count = count_requests(ip, cutoff)

    remaining = max(max_requests - count, 0)
    retry_after_secs = div(window_ms, 1000)
    reset_unix = System.os_time(:second) + retry_after_secs

    conn = add_rate_limit_headers(conn, max_requests, remaining, reset_unix)

    if count > max_requests do
      Logger.warning("[RateLimiter] Rate limit exceeded for #{ip} (#{count}/#{max_requests})")

      conn
      |> add_resp_header("retry-after", Integer.to_string(retry_after_secs))
      |> Ignite.Controller.json(
        %{
          error: "Too Many Requests",
          message: "Rate limit exceeded. Try again in #{retry_after_secs} seconds.",
          retry_after: retry_after_secs
        },
        429
      )
    else
      conn
    end
  end

  # --- Callbacks ---

  @impl true
  def init(_opts) do
    :ets.new(@table, [
      :named_table,
      :bag,
      :public,
      write_concurrency: true,
      read_concurrency: true
    ])

    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    config = Application.get_env(:ignite, :rate_limit, [])
    window_ms = Keyword.get(config, :window_ms, @default_window_ms)
    cutoff = System.monotonic_time(:millisecond) - window_ms

    # Delete older than window
    match_spec = [{{:_, :"$1"}, [{:<, :"$1", cutoff}], [true]}]
    deleted = :ets.select_delete(@table, match_spec)

    if deleted > 0 do
      Logger.debug("[RateLimiter] Cleaned up #{deleted} expired entries")
    end

    schedule_cleanup()
    {:noreply, state}
  end

  # --- Helpers ---

  defp count_requests(ip, cutoff) do
    match_spec = [{{ip, :"$1"}, [{:>=, :"$1", cutoff}], [true]}]
    :ets.select_count(@table, match_spec)
  end

  defp client_ip(conn) do
    case Map.get(conn.headers, "x-forwarded-for") do
      nil -> Map.get(conn.private, :peer_ip, "unknown")
      forwarded -> forwarded |> String.split(",") |> List.first() |> String.trim()
    end
  end

  defp add_rate_limit_headers(conn, limit, remaining, reset_unix) do
    new_headers =
      conn.resp_headers
      |> Map.put("x-ratelimit-limit", Integer.to_string(limit))
      |> Map.put("x-ratelimit-remaining", Integer.to_string(remaining))
      |> Map.put("x-ratelimit-reset", Integer.to_string(reset_unix))

    %Ignite.Conn{conn | resp_headers: new_headers}
  end

  defp add_resp_header(conn, key, value) do
    new_headers = Map.put(conn.resp_headers, key, value)
    %Ignite.Conn{conn | resp_headers: new_headers}
  end

  defp schedule_cleanup do
    config = Application.get_env(:ignite, :rate_limit, [])
    window_ms = Keyword.get(config, :window_ms, @default_window_ms)
    interval = min(window_ms, 60_000)
    Process.send_after(self(), :cleanup, interval)
  end
end
