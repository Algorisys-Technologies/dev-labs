defmodule MyApp.Router do
  @moduledoc """
  Defines the routes for our application.

  Each `get` line generates a pattern-matched function clause
  at compile time. The router tries each one in order until
  it finds a match.
  """

  use Ignite.Router

  get "/", to: MyApp.WelcomeController, action: :index
  get "/hello", to: MyApp.WelcomeController, action: :hello
  get "/users/:id", to: MyApp.UserController, action: :show

  finalize_routes()
end
