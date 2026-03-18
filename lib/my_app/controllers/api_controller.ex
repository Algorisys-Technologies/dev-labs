defmodule MyApp.ApiController do
  import Ignite.Controller

  def status(conn) do
    json(conn, %{
      status: "ok",
      framework: "Ignite",
      elixir_version: System.version()
    })
  end

  def echo(conn) do
    json(conn, %{echo: conn.params})
  end
end
