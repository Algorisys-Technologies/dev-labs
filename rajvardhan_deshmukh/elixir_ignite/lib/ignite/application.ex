defmodule ElixirIgnite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the TCP server on port 4000.
      # The Supervisor will restart it automatically if it crashes.
      {Ignite.Server, 4000}
    ]

    opts = [strategy: :one_for_one, name: Ignite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
