defmodule MyApp.Router do
  use Ignite.Router

  get "/", to: MyApp.WelcomeController, action: :index
  get "/hello", to: MyApp.WelcomeController, action: :hello

  finalize_routes()
end
