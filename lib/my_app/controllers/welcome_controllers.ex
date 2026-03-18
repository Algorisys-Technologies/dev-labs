# lib/ignite/my_app/controllers/welcome_controllers.ex
defmodule MyApp.WelcomeController do
  import Ignite.Controller

  def index(conn) do
    flash = get_flash(conn)

    flash_html =
      Enum.map_join(flash, "\n", fn {type, msg} ->
        {bg, border, color} =
          case type do
            "info" -> {"#d4edda", "#c3e6cb", "#155724"}
            "error" -> {"#f8d7da", "#f5c6cb", "#721c24"}
            _ -> {"#e2e3e5", "#d6d8db", "#383d41"}
          end

        """
        <div style="background:#{bg}; border:1px solid #{border}; color:#{color}; padding:10px; margin-bottom:20px; border-radius:4px;">
          #{msg}
        </div>
        """
      end)

    # Passing raw HTML to the live template via @body
    render(conn, "live", body: """
    #{flash_html}
    <h3>Create User</h3>
      <form action="/users" method="POST" style="background:#f9f9f9; padding:15px; border-radius:8px; border:1px solid #eee;">
        <div style="margin-bottom:10px;">
          <input type="text" name="username" placeholder="Username" style="padding:8px; border:1px solid #ddd; border-radius:4px; width:200px;" required>
        </div>
        <div style="margin-bottom:10px;">
          <input type="email" name="email" placeholder="Email (optional)" style="padding:8px; border:1px solid #ddd; border-radius:4px; width:200px;">
        </div>
        <button type="submit" style="padding:8px 16px; background:#007bff; color:white; border:none; border-radius:4px; cursor:pointer;">Create User</button>
      </form>
    <h1>Welcome to Ignite!</h1>
    <h2>API Routes</h2>
    <ul>
      <li><a href="/hooks-demo" ignite-navigate="/hooks-demo">/hooks-demo</a> — LiveView with JS Hooks</li>
      <li><a href="/shared-counter" ignite-navigate="/shared-counter">/shared-counter</a> — PubSub Shared Counter</li>
      <li><a href="/components" ignite-navigate="/components">/components</a> — LiveComponents Demo</li>
      <li><a href="/streams" ignite-navigate="/streams">/streams</a> — LiveView Streams Demo</li>
      <li><a href="/upload">/upload</a> — Traditional File Upload</li>
      <li><a href="/upload-demo" ignite-navigate="/upload-demo">/upload-demo</a> — LiveView File Upload Demo</li>
      <li><a href="/presence" ignite-navigate="/presence">/presence</a> — Presence "Who's Online" Demo</li>
      <li><a href="/api/status">/api/status</a> — JSON response</li>
    </ul>

    <h3>Path Helpers (Tutorial 27)</h3>
    <ul>
      <li><code>user_path(:index)</code> -> <%= MyApp.Router.Helpers.user_path(:index) %></li>
      <li><code>user_path(:show, 123)</code> -> <%= MyApp.Router.Helpers.user_path(:show, 123) %></li>
      <li><code>api_status_path(:status)</code> -> <%= MyApp.Router.Helpers.api_status_path(:status) %></li>
    </ul>
    """, module: "Welcome", rendered: "{}", live_routes: "{}")
  end

  def streams(conn) do
    render_live(conn, MyApp.StreamDemoLive)
  end

  def upload_demo(conn) do
    render_live(conn, MyApp.UploadDemoLive)
  end

  def presence(conn) do
    render_live(conn, MyApp.PresenceDemoLive)
  end
  
  def hello(conn), do: text(conn, "Hello from the Controller!")

  def test_render(conn) do
    render(conn, "live", name: "Ignite User", version: "1.0")
  end

  def test_error(_conn) do
    raise "BOOM! Testing the Error Handler."
  end
end
