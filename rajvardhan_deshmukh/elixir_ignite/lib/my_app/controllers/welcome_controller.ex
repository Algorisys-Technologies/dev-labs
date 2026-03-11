defmodule MyApp.WelcomeController do
  @moduledoc """
  Handles requests for the welcome pages.

  Each function receives an %Ignite.Conn{} and returns a new
  %Ignite.Conn{} with the response body filled in using helpers.
  """

  import Ignite.Controller

  def index(conn), do: text(conn, "Welcome to Ignite!")

  def hello(conn), do: text(conn, "Hello from the Controller!")
end
