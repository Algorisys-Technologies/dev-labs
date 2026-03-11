# lib/ignite/my_app/controllers/welcome_controllers.ex
defmodule MyApp.WelcomeController do
  import Ignite.Controller

  def index(conn), do: text(conn, "Welcome to Ignite!")
  def hello(conn), do: text(conn, "Hello from the Controller!")
end
