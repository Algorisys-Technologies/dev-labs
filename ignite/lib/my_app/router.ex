defmodule MyApp.Router do
  use Ignite.Router

  # Middleware pipeline
  plug :log_request
  plug :add_server_header

  # Look how easy it is to read! This is called a Domain Specific Language (DSL).
  get("/", to: MyApp.WelcomeController, action: :index)
  get("/hello", to: MyApp.WelcomeController, action: :hello)
  get("/users/:id", to: MyApp.UserController, action: :show)
  post("/users", to: MyApp.UserController, action: :create)

  # Step 11: Error Handler test route
  get("/crash", to: MyApp.WelcomeController, action: :crash)

  # Step 12-14: LiveView route
    get "/counter", to: MyApp.WelcomeController, action: :counter
    get "/dashboard", to: MyApp.WelcomeController, action: :dashboard
    get "/shared-counter", to: MyApp.WelcomeController, action: :shared_counter
    get "/components", to: MyApp.WelcomeController, action: :components
    get "/hooks", to: MyApp.WelcomeController, action: :hooks

  finalize_routes()

  # --- Plug Implementations ---

  def log_request(conn) do
    require Logger
    Logger.info("[Ignite] #{conn.method} #{conn.path}")
    conn
  end

  def add_server_header(%Ignite.Conn{} = conn) do
    new_headers = Map.put(conn.resp_headers, "x-powered-by", "Ignite")
    %Ignite.Conn{conn | resp_headers: new_headers}
  end
  get "/api/status", to: MyApp.ApiController, action: :status
  post "/api/echo", to: MyApp.ApiController, action: :echo
end
