defmodule MyApp.Router do
  use Ignite.Router
  require Logger

  plug :log_request
  plug :add_server_header

  get "/", to: MyApp.WelcomeController, action: :index
  get "/hello", to: MyApp.WelcomeController, action: :hello
  get "/users/:id", to: MyApp.UserController, action: :show
  post "/users", to: MyApp.UserController, action: :create

  # Plug implementations
  def log_request(conn) do
    Logger.info("[Ignite] #{conn.method} #{conn.path}")
    conn
  end

  def add_server_header(conn) do
    new_headers = Map.put(conn.resp_headers, "x-powered-by", "Ignite")
    %Ignite.Conn{conn | resp_headers: new_headers}
  end

  finalize_routes()
end
