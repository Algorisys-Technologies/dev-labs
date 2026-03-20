defmodule MyApp.Router do
  use Ignite.Router
  require Logger

  plug :rate_limit
  plug :fetch_flash
  plug :set_hsts_header
  plug :set_csp_headers
  plug :add_server_header
  plug :verify_csrf_token

  get "/", to: MyApp.WelcomeController, action: :index
  get "/hello", to: MyApp.WelcomeController, action: :hello
  resources "/users", MyApp.UserController
  get "/crash", to: MyApp.WelcomeController, action: :crash
  get "/counter", to: MyApp.WelcomeController, action: :counter
  get "/dashboard", to: MyApp.WelcomeController, action: :dashboard
  get "/shared-counter", to: MyApp.WelcomeController, action: :shared_counter
  get "/streams", to: MyApp.WelcomeController, action: :streams
  get "/upload", to: MyApp.UploadController, action: :upload_form
  post "/upload", to: MyApp.UploadController, action: :upload
  get "/upload-demo", to: MyApp.WelcomeController, action: :upload_demo
  get "/components", to: MyApp.WelcomeController, action: :components
  get "/hooks", to: MyApp.WelcomeController, action: :hooks
  get "/helpers", to: MyApp.WelcomeController, action: :helpers
  get "/presence", to: MyApp.WelcomeController, action: :presence
  get "/health", to: MyApp.ApiController, action: :health

  # API Routes grouped under /api
  scope "/api" do
    get "/status", to: MyApp.ApiController, action: :status
    post "/echo", to: MyApp.ApiController, action: :echo
  end

  # Plug implementations

  def rate_limit(conn) do
    Ignite.RateLimiter.call(conn)
  end

  def fetch_flash(conn) do
    flash = Map.get(conn.session, "_flash", %{})
    %Ignite.Conn{conn | private: Map.put(conn.private, :flash, flash)}
  end

  def set_hsts_header(conn) do
    Ignite.HSTS.put_hsts_header(conn)
  end

  def set_csp_headers(conn) do
    Ignite.CSP.put_csp_headers(conn)
  end

  def add_server_header(conn) do
    new_headers = Map.put(conn.resp_headers, "x-powered-by", "Ignite")
    %Ignite.Conn{conn | resp_headers: new_headers}
  end

  def verify_csrf_token(%Ignite.Conn{method: method} = conn)
      when method in ["GET", "HEAD", "OPTIONS"] do
    conn
  end

  def verify_csrf_token(conn) do
    content_type = Map.get(conn.headers, "content-type", "")

    if String.starts_with?(content_type, "application/json") do
      conn
    else
      session_token = conn.session["_csrf_token"]
      submitted_token = conn.params["_csrf_token"]

      if Ignite.CSRF.valid_token?(session_token, submitted_token) do
        conn
      else
        conn |> Ignite.Controller.html(csrf_error_page(), 403)
      end
    end
  end

  defp csrf_error_page do
    """
    <!DOCTYPE html>
    <html>
    <head><title>403 Forbidden</title></head>
    <body style="font-family: system-ui; max-width: 600px; margin: 50px auto;">
      <h1 style="color: #e74c3c;">403 Forbidden</h1>
      <p>Invalid or missing CSRF token. This usually means:</p>
      <ul>
        <li>Your session expired — try refreshing the page</li>
        <li>The form is missing a CSRF token tag</li>
      </ul>
      <p><a href="/">Back to Home</a></p>
    </body>
    </html>
    """
  end

  finalize_routes()
end
