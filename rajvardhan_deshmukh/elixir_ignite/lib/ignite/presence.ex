defmodule Ignite.Presence do
  @moduledoc """
  Real-time presence tracking for Ignite LiveViews.

  Tracks which processes (WebSocket connections) are currently "present"
  under a given topic, with arbitrary metadata. Uses `Process.monitor/1`
  for auto-cleanup: when a WebSocket process dies, it is automatically
  untracked and a leave diff is broadcast to all subscribers.

  State shape:
    presences: %{topic => %{key => %{pid: pid, meta: map, ref: reference}}}
    refs:      %{monitor_ref => {topic, key}}
  """

  use GenServer

  # ── Public API ──

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Track the calling process under `topic` with the given `key` and `meta`."
  def track(topic, key, meta \\ %{}) do
    GenServer.call(__MODULE__, {:track, topic, key, meta, self()})
  end

  @doc "Remove the calling process from `topic` under `key`."
  def untrack(topic, key) do
    GenServer.call(__MODULE__, {:untrack, topic, key, self()})
  end

  @doc "List all presences for a given topic. Returns `%{key => meta}`."
  def list(topic) do
    GenServer.call(__MODULE__, {:list, topic})
  end

  # ── GenServer callbacks ──

  @impl true
  def init(_opts) do
    {:ok, %{presences: %{}, refs: %{}}}
  end

  @impl true
  def handle_call({:track, topic, key, meta, pid}, _from, state) do
    state = do_track(state, topic, key, meta, pid)
    {:reply, :ok, state}
  end

  def handle_call({:untrack, topic, key, _pid}, _from, state) do
    state = do_untrack(state, topic, key)
    {:reply, :ok, state}
  end

  def handle_call({:list, topic}, _from, state) do
    topic_presences = Map.get(state.presences, topic, %{})
    result = Map.new(topic_presences, fn {key, %{meta: meta}} -> {key, meta} end)
    {:reply, result, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.get(state.refs, ref) do
      nil ->
        {:noreply, state}

      {topic, key} ->
        # Get meta before removing so we can broadcast it
        meta =
          case get_in(state.presences, [topic, key]) do
            %{meta: m} -> m
            _ -> %{}
          end

        # Remove from state
        new_presences =
          case Map.get(state.presences, topic) do
            nil -> state.presences
            topic_map ->
              updated = Map.delete(topic_map, key)
              if map_size(updated) == 0 do
                Map.delete(state.presences, topic)
              else
                Map.put(state.presences, topic, updated)
              end
          end

        new_refs = Map.delete(state.refs, ref)

        # Broadcast leave diff — send directly because the dead process
        # can't be excluded as a sender via PubSub.broadcast
        diff = {:presence_diff, %{joins: %{}, leaves: %{key => meta}}}
        for pid <- :pg.get_members(Ignite.PubSub, topic) do
          send(pid, diff)
        end

        {:noreply, %{state | presences: new_presences, refs: new_refs}}
    end
  end

  # ── Private helpers ──

  defp do_track(state, topic, key, meta, pid) do
    ref = Process.monitor(pid)

    presence = %{pid: pid, meta: meta, ref: ref}

    new_presences =
      Map.update(state.presences, topic, %{key => presence}, fn topic_map ->
        Map.put(topic_map, key, presence)
      end)

    new_refs = Map.put(state.refs, ref, {topic, key})

    # Broadcast join diff via PubSub
    Ignite.PubSub.broadcast(topic, {:presence_diff, %{joins: %{key => meta}, leaves: %{}}})

    %{state | presences: new_presences, refs: new_refs}
  end

  defp do_untrack(state, topic, key) do
    case get_in(state.presences, [topic, key]) do
      nil ->
        state

      %{ref: ref, meta: meta} ->
        Process.demonitor(ref, [:flush])

        new_presences =
          case Map.get(state.presences, topic) do
            nil -> state.presences
            topic_map ->
              updated = Map.delete(topic_map, key)
              if map_size(updated) == 0 do
                Map.delete(state.presences, topic)
              else
                Map.put(state.presences, topic, updated)
              end
          end

        new_refs = Map.delete(state.refs, ref)

        # Broadcast leave diff via PubSub
        Ignite.PubSub.broadcast(topic, {:presence_diff, %{joins: %{}, leaves: %{key => meta}}})

        %{state | presences: new_presences, refs: new_refs}
    end
  end
end
