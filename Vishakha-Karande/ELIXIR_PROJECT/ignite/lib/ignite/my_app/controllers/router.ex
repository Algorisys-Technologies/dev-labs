defmodule MyApp.Router do
  use Ignite.Router

  # Look how easy it is to read! This is called a Domain Specific Language (DSL).
  get("/", to: MyApp.WelcomeController, action: :index)
  get("/hello", to: MyApp.WelcomeController, action: :hello)
  get("/users/:id", to: MyApp.UserController, action: :show)

  finalize_routes()
end
