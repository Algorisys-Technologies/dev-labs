# lib/ignite/my_app/controllers/welcome_controllers.ex
defmodule MyApp.WelcomeController do
  import Ignite.Controller

  def index(conn), do: text(conn, "Welcome to Ignite!")

  def crash(_conn) do
    raise "This is a test crash!"
  end

  def counter(conn) do
    render(conn, "live", title: "Live Counter — Ignite")
  end
end
