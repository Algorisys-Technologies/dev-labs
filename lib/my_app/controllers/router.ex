defmodule MyApp.Router do
  use Ignite.Router

  # Look how easy it is to read! This is called a Domain Specific Language (DSL).
  plug :rate_limit
  plug :set_hsts_header
  plug :set_csp_headers
  plug :verify_csrf_token

  @doc """
  Rate limiting plug — rejects requests exceeding the configured
  requests-per-window limit with 429 Too Many Requests.
  """
  def rate_limit(conn), do: Ignite.RateLimiter.call(conn)

  def set_hsts_header(conn), do: Ignite.HSTS.put_hsts_header(conn)

  def set_csp_headers(conn) do
    Ignite.CSP.put_csp_headers(conn)
  end

  def verify_csrf_token(%Ignite.Conn{method: method} = conn)
      when method in ["GET", "HEAD", "OPTIONS"] do
    conn
  end

  def verify_csrf_token(conn) do
    content_type = Map.get(conn.headers, "content-type", "")

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

  get("/", to: MyApp.WelcomeController, action: :index)
  get("/health", to: MyApp.ApiController, action: :health)
  get("/hello", to: MyApp.WelcomeController, action: :hello)
  resources "/users", MyApp.UserController

  # Validation Routes
  get("/test-render", to: MyApp.WelcomeController, action: :test_render)
  get("/test-error", to: MyApp.WelcomeController, action: :test_error)

  # Upload Routes
  get("/upload", to: MyApp.UploadController, action: :upload_form)
  post("/upload", to: MyApp.UploadController, action: :upload)
  get("/upload-demo", to: MyApp.WelcomeController, action: :upload_demo)

  scope "/api" do
    get("/status", to: MyApp.ApiController, action: :status)
    post("/echo", to: MyApp.ApiController, action: :echo)
  end

  live("/hooks-demo", MyApp.HooksDemoLive)
  live("/shared-counter", MyApp.SharedCounterLive)
  live("/components", MyApp.ComponentsDemoLive)
  live("/streams", MyApp.StreamDemoLive)
  live("/presence", MyApp.PresenceDemoLive)
  live("/feex-test", MyApp.FEExTestLive)
  live("/todo", MyApp.TodoLive)
  live("/todos", MyApp.TodoLive)

  finalize_routes()
end
