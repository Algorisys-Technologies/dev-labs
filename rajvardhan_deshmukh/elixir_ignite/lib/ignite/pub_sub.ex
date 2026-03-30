defmodule Ignite.PubSub do
  @moduledoc """
  A lightweight publish/subscribe system built on Erlang's :pg.
  """

  def start_link(_opts) do
    :pg.start_link(__MODULE__)
  end

  def subscribe(topic) do
    :pg.join(__MODULE__, topic, self())
  end

  def broadcast(topic, message) do
    for pid <- :pg.get_members(__MODULE__, topic), pid != self() do
      send(pid, message)
    end
    :ok
  end

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end
end
