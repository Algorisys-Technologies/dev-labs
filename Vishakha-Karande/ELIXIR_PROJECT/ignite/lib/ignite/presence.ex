# lib/ignite/presence.ex
defmodule Ignite.Presence do
  @moduledoc """
  A simple presence tracking system using process monitors.
  """
  use GenServer
  require Logger

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def track(topic, key, meta \\ %{}) do
    GenServer.call(__MODULE__, {:track, topic, key, meta, self()})
  end

  def untrack(topic, key) do
    GenServer.call(__MODULE__, {:untrack, topic, key, self()})
  end

  def list(topic) do
    GenServer.call(__MODULE__, {:list, topic})
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_opts) do
    {:ok, %{presences: %{}, refs: %{}}}
  end

  @impl true
  def handle_call({:track, topic, key, meta, pid}, _from, state) do
    state = do_track(state, topic, key, meta, pid)
    # Broadcast join
    Ignite.PubSub.broadcast(topic, {:presence_diff, %{joins: %{key => meta}, leaves: %{}}})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:untrack, topic, key, pid}, _from, state) do
    topic_presences = Map.get(state.presences, topic, %{})

    case Map.get(topic_presences, key) do
      %{pid: ^pid, ref: ref, meta: meta} ->
        Process.demonitor(ref, [:flush])
        state = remove_presence(state, topic, key, ref)
        # Broadcast leave
        Ignite.PubSub.broadcast(topic, {:presence_diff, %{joins: %{}, leaves: %{key => meta}}})
        {:reply, :ok, state}

      _ ->
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:list, topic}, _from, state) do
    result =
      state.presences
      |> Map.get(topic, %{})
      |> Map.new(fn {key, %{meta: meta}} -> {key, meta} end)

    {:reply, result, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.get(state.refs, ref) do
      {topic, key} ->
        meta = get_in(state.presences, [topic, key, :meta]) || %{}
        state = remove_presence(state, topic, key, ref)

        # Send directly because the dead process can't be excluded as a sender
        for pid <- :pg.get_members(topic) do
          send(pid, {:pubsub, topic, {:presence_diff, %{joins: %{}, leaves: %{key => meta}}}})
        end

        {:noreply, state}

      nil ->
        {:noreply, state}
    end
  end

  # --- Private ---

  defp do_track(state, topic, key, meta, pid) do
    ref = Process.monitor(pid)
    topic_presences = Map.get(state.presences, topic, %{})
    updated = Map.put(topic_presences, key, %{pid: pid, meta: meta, ref: ref})

    %{
      state
      | presences: Map.put(state.presences, topic, updated),
        refs: Map.put(state.refs, ref, {topic, key})
    }
  end

  defp remove_presence(state, topic, key, ref) do
    topic_presences = Map.get(state.presences, topic, %{})
    updated = Map.delete(topic_presences, key)

    presences =
      if updated == %{},
        do: Map.delete(state.presences, topic),
        else: Map.put(state.presences, topic, updated)

    %{state | presences: presences, refs: Map.delete(state.refs, ref)}
  end
end
