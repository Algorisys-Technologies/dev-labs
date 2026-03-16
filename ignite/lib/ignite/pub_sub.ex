defmodule Ignite.PubSub do
  def start_link(_opts), do: :pg.start_link(__MODULE__)

  def subscribe(topic), do: :pg.join(__MODULE__, topic, self())

  def broadcast(topic, message) do
    require Logger
    members = :pg.get_members(__MODULE__, topic)
    Logger.info("[PubSub] Topic #{inspect(topic)}: Broadcasting #{inspect(message)} to #{length(members)} members")

    # 💡 ANTI-LOOP FILTER: Don't send the message back to ourselves!
    for pid <- members, pid != self() do
      Logger.info("[PubSub] Sending to #{inspect(pid)}")
      send(pid, message)
    end

    :ok
  end

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end
end
