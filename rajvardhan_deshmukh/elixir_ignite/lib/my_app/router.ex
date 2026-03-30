defmodule MyApp.Router do
  @moduledoc """
  Defines the routes for our application.

  Each `get` line generates a pattern-matched function clause
  at compile time. The router tries each one in order until
  it finds a match.
  """

  use Ignite.Router

  # --- Plug Pipeline ---
  # These run in the order they are defined.
  plug :rate_limit
  plug :add_server_header
  plug :set_csp_headers
  plug :set_hsts_header
  plug :verify_csrf_token

  # A plug is just a function that takes a conn and returns a conn.
  def log_request(conn) do
    Logger.info("[Ignite] #{conn.method} #{conn.path}")
    conn
  end

  def add_server_header(%Ignite.Conn{} = conn) do
    # You can modify the resp_headers map directly
    new_headers = Map.put(conn.resp_headers, "x-powered-by", "Ignite")
    %{conn | resp_headers: new_headers}
  end

  # CSP Headers Plug
  def set_csp_headers(conn) do
    Ignite.CSP.put_csp_headers(conn)
  end

  # HSTS Header Plug
  def set_hsts_header(conn) do
    Ignite.HSTS.put_hsts_header(conn)
  end

  @doc """
  Rate limiting plug — rejects requests exceeding the configured
  requests-per-window limit with 429 Too Many Requests.
  """
  def rate_limit(conn) do
    Ignite.RateLimiter.call(conn)
  end

  # --- Routes ---
  get "/", to: MyApp.WelcomeController, action: :index
  get "/hello", to: MyApp.WelcomeController, action: :hello
  get "/health", to: MyApp.ApiController, action: :health
  # get "/users/:id" is now handled by resources "/users" below
  get "/crash", to: MyApp.WelcomeController, action: :crash
  get "/counter", to: MyApp.WelcomeController, action: :counter
  get "/dashboard", to: MyApp.WelcomeController, action: :dashboard
  get "/shared-counter", to: MyApp.WelcomeController, action: :shared_counter
  get "/components", to: MyApp.WelcomeController, action: :components
  get "/hooks", to: MyApp.WelcomeController, action: :hooks
  get "/streams", to: MyApp.WelcomeController, action: :streams
  get "/presence", to: MyApp.WelcomeController, action: :presence
  get "/todo", to: MyApp.WelcomeController, action: :todo

  get "/upload", to: MyApp.WelcomeController, action: :upload_form
  post "/upload", to: MyApp.WelcomeController, action: :upload
  get "/upload-demo", to: MyApp.WelcomeController, action: :upload_demo

  # Standard RESTful routes via resources/3 (Step 27)
  resources "/users", MyApp.UserController

  # JSON API (Step 21 & Step 23)
  scope "/api" do
    get "/status", to: MyApp.ApiController, action: :status
    post "/echo", to: MyApp.ApiController, action: :echo
  end

  # CSRF Verification Plug
  def verify_csrf_token(%Ignite.Conn{method: method} = conn)
      when method in ["GET", "HEAD", "OPTIONS"] do
    conn
  end

  def verify_csrf_token(conn) do
    content_type = Map.get(conn.req_headers, "content-type", "")

    if String.starts_with?(content_type, "application/json") do
      conn # JSON APIs exempt — protected by SameSite cookies + CORS
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
    <div style="max-width: 500px; margin: 100px auto; font-family: sans-serif; text-align: center;">
      <h1 style="color: #e74c3c;">403 Forbidden</h1>
      <p style="color: #34495e; font-size: 1.2em; font-weight: bold;">Bye bye hacker! 👋</p>
      <p style="color: #636e72;">Invalid or missing CSRF token.</p>
      <div style="margin-top: 20px;">
        <a href="/" style="color: #3498db; text-decoration: none;">Return Home</a>
      </div>
    </div>
    """
  end

end
