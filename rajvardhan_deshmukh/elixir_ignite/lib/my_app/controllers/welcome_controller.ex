defmodule MyApp.WelcomeController do
  @moduledoc """
  Handles requests for the welcome pages.

  Each function receives an %Ignite.Conn{} and returns a new
  %Ignite.Conn{} with the response body filled in using helpers.
  """

  import Ignite.Controller

  def index(conn) do
    flash = get_flash(conn)

    flash_html =
      case flash do
        f when f == %{} -> ""
        f ->
          Enum.map_join(f, "\n", fn {type, msg} ->
            {bg, border, color} = case type do
              "info"  -> {"#d4edda", "#c3e6cb", "#155724"}
              "error" -> {"#f8d7da", "#f5c6cb", "#721c24"}
              _       -> {"#e2e3e5", "#d6d8db", "#383d41"}
            end

            """
            <div style="background: #{bg}; border: 1px solid #{border}; color: #{color};
                        padding: 12px 20px; border-radius: 6px; margin: 10px auto;
                        max-width: 600px; font-family: sans-serif; font-size: 0.95em;">
              #{msg}
            </div>
            """
          end)
      end

    nonce =
      if Code.ensure_loaded?(Ignite.Security.CSP) and function_exported?(Ignite.Security.CSP, :get_nonce, 1) do
        apply(Ignite.Security.CSP, :get_nonce, [conn]) || "dummy_nonce"
      else
        "dummy_nonce"
      end

    conn
    |> html("""
    #{flash_html}
    <h1>Ignite Framework</h1>
    <p>A Phoenix-like web framework built from scratch.</p>
    <h2>Demo Routes</h2>
    <ul>
      <li><a href="/hello">/hello</a> — Controller response</li>
      <li><a href="/users/42">/users/42</a> — EEx template with dynamic params</li>
      <li><a href="/counter">/counter</a> — LiveView (real-time counter)</li>
      <li><a href="/register">/register</a> — LiveView form with real-time validation</li>
      <li><a href="/dashboard">/dashboard</a> — Live BEAM dashboard (auto-refresh)</li>
      <li><a href="/shared-counter">/shared-counter</a> — PubSub shared counter (open in multiple tabs)</li>
      <li><a href="/components">/components</a> — LiveComponents (reusable stateful widgets)</li>
      <li><a href="/hooks">/hooks</a> — JS Hooks (client-side interop)</li>
      <li><a href="/streams">/streams</a> — LiveView Streams (efficient list updates)</li>
      <li><a href="/presence">/presence</a> — Presence tracking (who's online)</li>
      <li><a href="/upload">/upload</a> — File upload (multipart HTTP POST)</li>
      <li><a href="/upload-demo">/upload-demo</a> — LiveView uploads (chunked WebSocket)</li>
      <li><a href="/users">/users</a> — Resource route (JSON index)</li>
      <li><a href="/crash">/crash</a> — Error handler (500 page)</li>
      <li><a href="/todo"><strong>/todo</strong></a> — Full Todo App example (auth, CRUD, pagination, search, favorites, categories, subtasks)</li>
    </ul>
    <h2>Flash Messages</h2>
    <form action="/users" method="POST" style="background:#f4f4f4;padding:1em;border-radius:6px;margin-bottom:1em;">
      #{csrf_token_tag(conn)}
      <label for="username"><strong>Create User:</strong></label>
      <input type="text" name="username" id="username" placeholder="Enter username" style="padding:6px 10px;border:1px solid #ccc;border-radius:4px;margin:0 8px;">
      <input type="email" name="email" id="email" placeholder="Email (optional)" style="padding:6px 10px;border:1px solid #ccc;border-radius:4px;margin:0 8px;">
      <button type="submit" style="padding:6px 16px;background:#007bff;color:#fff;border:none;border-radius:4px;cursor:pointer;">Create</button>
      <small style="display:block;margin-top:6px;color:#666;">Submits POST /users → CSRF check → Ecto changeset → flash → redirect</small>
    </form>
    <h2>Path Helpers</h2>
    <pre style="background:#f4f4f4;padding:1em;border-radius:4px;overflow-x:auto;">    MyApp.Router.Helpers.user_path(:index)       #=> "/users"
    MyApp.Router.Helpers.user_path(:show, 42)    #=> "/users/42"
    MyApp.Router.Helpers.root_path(:index)       #=> "/"
    MyApp.Router.Helpers.api_status_path(:status) #=> "/api/status"</pre>
    <h2>API Routes</h2>
    <ul>
      <li><a href="/api/status">/api/status</a> — JSON response</li>
    </ul>
    <h3>POST /api/echo</h3>
    <div style="margin-bottom:1em;">
      <textarea id="echo-input" rows="3" cols="50" style="font-family:monospace;">{"name":"Jose"}</textarea><br>
      <button id="echo-btn" style="margin-top:0.5em;">Send POST</button>
    </div>
    <pre id="echo-output" style="background:#f4f4f4;padding:0.5em;display:none;"></pre>
    <script nonce="#{nonce}">
      document.getElementById("echo-btn").addEventListener("click", function() {
        var body = document.getElementById("echo-input").value;
        var out = document.getElementById("echo-output");
        out.style.display = "block";
        out.textContent = "Sending...";
        fetch("/api/echo", {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: body
        })
        .then(function(r) { return r.json(); })
        .then(function(data) { out.textContent = JSON.stringify(data, null, 2); })
        .catch(function(err) { out.textContent = "Error: " + err; });
      });
    </script>
    """)
  end

  def hello(conn) do
    text(conn, "Hello from the Controller!")
  end

  def crash(_conn) do
    raise "This is a test crash!"
  end

  # The map of HTTP paths to LiveView WebSocket paths
  # We use our newly generated path helpers!
  defp live_routes do
    %{
      MyApp.Router.Helpers.counter_path(:counter) => "/live",
      MyApp.Router.Helpers.dashboard_path(:dashboard) => "/live/dashboard",
      MyApp.Router.Helpers.shared_counter_path(:shared_counter) => "/live/shared-counter",
      MyApp.Router.Helpers.component_path(:components) => "/live/components",
      MyApp.Router.Helpers.hook_path(:hooks) => "/live/hooks",
      MyApp.Router.Helpers.stream_path(:streams) => "/live/streams",
      MyApp.Router.Helpers.upload_demo_path(:upload_demo) => "/live/upload-demo",
      MyApp.Router.Helpers.presence_path(:presence) => "/live/presence",
      MyApp.Router.Helpers.todo_path(:todo) => "/live/todo"
    }
  end

  def hooks(conn) do
    render(conn, "live", title: "JS Hooks Demo — Ignite", live_path: "/live/hooks", live_routes: Jason.encode!(live_routes()))
  end

  def streams(conn) do
    render(conn, "live", title: "Activity Stream — Ignite", live_path: "/live/streams", live_routes: Jason.encode!(live_routes()))
  end

  def presence(conn) do
    render(conn, "live", title: "Who's Online — Ignite", live_path: "/live/presence", live_routes: Jason.encode!(live_routes()))
  end

  def components(conn) do
    render(conn, "live", title: "Components Demo — Ignite", live_path: "/live/components", live_routes: Jason.encode!(live_routes()))
  end

  def counter(conn) do
    render(conn, "live", title: "Live Counter — Ignite", live_path: "/live", live_routes: Jason.encode!(live_routes()))
  end

  def dashboard(conn) do
    render(conn, "live", title: "Dashboard — Ignite", live_path: "/live/dashboard", live_routes: Jason.encode!(live_routes()))
  end

  def todo(conn) do
    render(conn, "todo_live",
      title: "Todo App — Ignite",
      live_path: "/live/todo",
      live_routes: Jason.encode!(live_routes())
    )
  end

  def shared_counter(conn) do
    render(conn, "live", title: "Shared Counter — Ignite", live_path: "/live/shared-counter", live_routes: Jason.encode!(live_routes()))
  end

  def upload_demo(conn) do
    render(conn, "live", title: "Live Uploads — Ignite", live_path: "/live/upload-demo", live_routes: Jason.encode!(live_routes()))
  end

  def upload_form(conn) do
    html(conn, """
    <div style="max-width: 500px; margin: 50px auto; font-family: sans-serif;">
      <h1>HTTP Upload</h1>
      <form action="/upload" method="post" enctype="multipart/form-data" 
            style="border: 2px dashed #ccc; padding: 30px; border-radius: 10px; text-align: center;">
        #{csrf_token_tag(conn)}
        <input type="file" name="file" style="margin-bottom: 20px;" /><br/>
        <input type="text" name="description" placeholder="Description" style="margin-bottom: 20px; padding: 5px; width: 100%;" /><br/>
        <button type="submit" style="background: #db8febff; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer;">
          Upload File
        </button>
      </form>
      <div style="margin-top: 20px;">
        <a href="/">Back Home</a>
      </div>
    </div>
    """)
  end

  def upload(conn) do
    case conn.params["file"] do
      %Ignite.Upload{filename: filename, path: path} ->
        size = File.stat!(path).size
        desc = Map.get(conn.params, "description", "No description")
        text(conn, "Success! Received #{filename} (#{size} bytes). Description: #{desc}")

      _ ->
        text(conn, "Error: No file uploaded", 400)
    end
  end
end
