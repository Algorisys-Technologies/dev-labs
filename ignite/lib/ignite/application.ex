defmodule Ignite.Application do
  @moduledoc """
  The OTP Application for Ignite.

  Starts Cowboy as the HTTP server with our custom handler.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:ignite, :port, 4000)

    # Cowboy routing
    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {"/live", Ignite.LiveView.Handler, %{view: MyApp.CounterLive}},
           {"/assets/[...]", :cowboy_static, {:dir, "assets"}},
           {"/[...]", Ignite.Adapters.Cowboy, []}
         ]}
      ])

    children = [
      %{
        id: :cowboy_listener,
        start: {:cowboy, :start_clear, [
          :ignite_http,
          [port: port],
          %{env: %{dispatch: dispatch}}
        ]}
      }
    ] ++ dev_children()

    Logger.info("Ignite is heating up on http://localhost:#{port}")

    opts = [strategy: :one_for_one, name: Ignite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dev_children do
    if Mix.env() == :dev do
      [{Ignite.Reloader, [path: "lib"]}]
    else
      []
    end
  end
end
