defmodule MyApp.WelcomeController do
  import Ignite.Controller

  def index(conn) do
    flash_html =
      case get_flash(conn) do
        flash when flash == %{} ->
          ""

        flash ->
          Enum.map_join(flash, "\n", fn {type, msg} ->
            {bg, border, color} =
              case type do
                "info" -> {"#d1ecf1", "#bee5eb", "#0c5460"}
                "error" -> {"#f8d7da", "#f5c6cb", "#721c24"}
                _ -> {"#e2e3e5", "#d6d8db", "#383d41"}
              end

            """
            <div style="background:#{bg}; border:1px solid #{border}; color:#{color}; padding:15px; margin-bottom:20px; border-radius:4px;">
              #{msg}
            </div>
            """
          end)
      end

    html(conn, """
    #{flash_html}
    <h1>Welcome to Ignite!</h1>
    <p>Hot reloading is active.</p>
    <ul>
      <li><a href="/counter">Counter (LiveView)</a></li>
      <li><a href="/dashboard">Dashboard (Real-time)</a></li>
      <li><a href="/shared-counter">Shared Counter (PubSub)</a></li>
      <li><a href="/components">LiveComponents</a></li>
      <li><a href="/hooks">JS Hooks</a></li>
      <li><a href="/streams">LiveView Streams Demo</a></li>
      <li><a href="/upload">HTTP File Upload (Part A)</a></li>
      <li><a href="/upload-demo">LiveView Uploads (Part B)</a></li>
      <li><a href="/helpers"><strong>Path Helpers Demo (New)</strong></a></li>
      <li><a href="/presence"><strong>Presence Tracking Demo (New)</strong></a></li>
    </ul>

    <h2>Create User</h2>
    <form action="/users" method="POST">
      #{csrf_token_tag(conn)}
      <input type="text" name="username" placeholder="Username" style="padding: 8px; border-radius: 4px; border: 1px solid #ddd;">
      <input type="email" name="email" placeholder="Email" style="padding: 8px; border-radius: 4px; border: 1px solid #ddd;">
      <button type="submit" style="padding: 8px 16px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">Create User</button>
    </form>

    <h2>API Routes</h2>
    <ul>
      <li><a href="/api/status">/api/status</a> — JSON System Status</li>
    </ul>

    <h2>Echo API (AJAX + CSP Nonce)</h2>
    <div id="echo-response" style="margin-bottom:10px; padding:10px; background:#eee; min-height:20px; border-radius:4px; font-family:monospace; font-size:12px;">
      Response will appear here...
    </div>
    <button id="echo-btn" style="padding: 8px 16px; background: #2ecc71; color: white; border: none; border-radius: 4px; cursor: pointer;">
      Send POST to /api/echo
    </button>

    <script nonce="#{csp_nonce(conn)}">
      document.getElementById("echo-btn").addEventListener("click", () => {
        fetch("/api/echo", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message: "Hello from CSP!" })
        })
        .then(r => r.json())
        .then(data => {
          document.getElementById("echo-response").innerText = JSON.stringify(data);
        });
      });
    </script>
    """)
  end

  def hello(conn) do
    text(conn, "Hello from the Controller!")
  end

  def helpers(conn) do
    alias MyApp.Router.Helpers, as: Routes

    html(conn, """
    <h1>Path Helpers Demo</h1>
    <p>These URLs were generated using <code>MyApp.Router.Helpers</code>:</p>
    <ul>
      <li><code>Routes.user_path(:index)</code> &rarr; <a href="#{Routes.user_path(:index)}">#{Routes.user_path(:index)}</a></li>
      <li><code>Routes.user_path(:show, 42)</code> &rarr; <a href="#{Routes.user_path(:show, 42)}">#{Routes.user_path(:show, 42)}</a></li>
      <li><code>Routes.api_status_path(:status)</code> &rarr; <a href="#{Routes.api_status_path(:status)}">#{Routes.api_status_path(:status)}</a></li>
      <li><code>Routes.root_path(:index)</code> &rarr; <a href="#{Routes.root_path(:index)}">#{Routes.root_path(:index)}</a></li>
    </ul>
    <p><a href="/">&larr; Back to Home</a></p>
    """)
  end

  def crash(_conn) do
    raise "This is a test crash!"
  end

  @live_routes Jason.encode!(%{
                 "/counter" => "/live",
                 "/dashboard" => "/live/dashboard",
                 "/shared-counter" => "/live/shared-counter",
                 "/components" => "/live/components",
                 "/hooks" => "/live/hooks",
                 "/streams" => "/live/streams",
                 "/upload-demo" => "/live/upload-demo",
                 "/presence" => "/live/presence"
               })

  def counter(conn) do
    render(conn, "live", title: "Live Counter — Ignite", live_path: "/live", live_routes: @live_routes)
  end

  def dashboard(conn) do
    render(conn, "live",
      title: "Dashboard — Ignite",
      live_path: "/live/dashboard",
      live_routes: @live_routes
    )
  end

  def shared_counter(conn) do
    render(conn, "live",
      title: "Shared Counter — Ignite",
      live_path: "/live/shared-counter",
      live_routes: @live_routes
    )
  end

  def components(conn) do
    render(conn, "live",
      title: "LiveComponents — Ignite",
      live_path: "/live/components",
      live_routes: @live_routes
    )
  end

  def hooks(conn) do
    render(conn, "live",
      title: "JS Hooks — Ignite",
      live_path: "/live/hooks",
      live_routes: @live_routes
    )
  end

  def streams(conn) do
    render(conn, "live",
      title: "LiveView Streams — Ignite",
      live_path: "/live/streams",
      live_routes: @live_routes
    )
  end

  def upload_demo(conn) do
    render(conn, "live",
      title: "LiveView Uploads — Ignite",
      live_path: "/live/upload-demo",
      live_routes: @live_routes
    )
  end

  def presence(conn) do
    render(conn, "live",
      title: "Who's Online — Ignite",
      live_path: "/live/presence",
      live_routes: @live_routes
    )
  end
end
