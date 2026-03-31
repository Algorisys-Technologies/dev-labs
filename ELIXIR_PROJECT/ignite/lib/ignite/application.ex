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
    Ignite.Static.init()

    # Cowboy routing: send ALL requests to our adapter
    dispatch =
      :cowboy_router.compile([
        {:_, [
          {"/live", Ignite.LiveView.Handler, []},
          {"/assets/[...]", :cowboy_static, {:dir, "assets"}},
          {"/[...]", Ignite.Adapters.Cowboy, []}
        ]}
      ])

    children = [
      MyApp.Repo,
      %{
        id: :pg,
        start: {:pg, :start_link, []}
      },
      Ignite.Presence,
      Ignite.RateLimiter,
      # Start Cowboy — HTTP or HTTPS depending on :ssl config (Step 39)
      Ignite.SSL.child_spec(port, dispatch)
    ] ++ redirect_children(port) ++ dev_children()

    scheme = if Ignite.SSL.ssl_configured?(), do: "https", else: "http"
    Logger.info("Ignite is heating up on #{scheme}://localhost:#{port}")

    opts = [strategy: :one_for_one, name: Ignite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Optional HTTP→HTTPS redirect listener (only when SSL is configured).
  # Set `config :ignite, http_redirect_port: 4080` to enable.
  defp redirect_children(https_port) do
    http_port = Application.get_env(:ignite, :http_redirect_port)

    if http_port && Ignite.SSL.ssl_configured?() do
      Logger.info("HTTP→HTTPS redirect on port #{http_port}")
      [Ignite.SSL.redirect_child_spec(http_port, https_port)]
    else
      []
    end
  end

  defp dev_children do
    if Application.get_env(:ignite, :env) == :dev do
      [{Ignite.Reloader, [path: "lib"]}]
    else
      []
    end
  end
end
