defmodule Ignite.PubSub do
  @moduledoc """
  Core PubSub system using Erlang's :pg (Process Groups).
  """

  @doc "Joins the current process to a topic."
  def subscribe(topic) do
    :pg.join(topic, self())
  end

  @doc "Broadcasts a message to all subscribers of a topic."
  def broadcast(topic, message) do
    for pid <- :pg.get_members(topic) do
      send(pid, {:pubsub, topic, message})
    end
    :ok
  end
end
