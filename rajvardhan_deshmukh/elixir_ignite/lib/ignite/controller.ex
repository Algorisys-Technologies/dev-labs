defmodule Ignite.Controller do
  @moduledoc """
  Response helpers for controllers.

  Import this module in your controllers to get access to
  `text/2`, `html/2`, and `send_resp/1`.

  ## Example

      defmodule MyApp.WelcomeController do
        import Ignite.Controller

        def index(conn), do: text(conn, "Hello!")
        def page(conn), do: html(conn, "<h1>Hello!</h1>")
      end
  """

  alias Ignite.Conn

  @doc """
  Sets a response header.
  """
  def put_resp_header(%Conn{} = conn, key, value) do
    new_headers = Map.put(conn.resp_headers, String.downcase(key), value)
    %Conn{conn | resp_headers: new_headers}
  end

  @doc """
  Sets the response status code.
  """
  def put_status(%Conn{} = conn, status) when is_integer(status) do
    %Conn{conn | status: status}
  end

  @doc """
  Sends a plain text response.

  Sets the content-type to "text/plain" and stores the body in the conn.
  """
  def text(%Conn{} = conn, body, status \\ 200) do
    %{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/plain; charset=utf-8"),
      halted: true
    }
  end

  @doc """
  Sends an HTML response.

  Sets the content-type to "text/html" and stores the body in the conn.
  """
  def html(%Conn{} = conn, body, status \\ 200) do
    %{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/html; charset=utf-8"),
      halted: true
    }
  end

  @doc """
  Sends a JSON response.

  Serializes the data using Jason and sets the content-type to "application/json".
  """
  def json(%Conn{} = conn, data, status \\ 200) do
    %{conn |
      status: status,
      resp_body: Jason.encode!(data),
      resp_headers: Map.put(conn.resp_headers, "content-type", "application/json"),
      halted: true
    }
  end

  @doc """
  Renders an EEx template from the `templates` directory.

  Takes the name of the template (without extension), and a keyword list
  of assigns to pass into the template.
  """
  def render(conn, template_name, assigns \\ []) do
    # 1. Build the full path to the template file
    template_path = Path.join("templates", "#{template_name}.html.eex")

    # 2. Evaluate the EEx file.
    # We convert the keyword list `assigns` into a map so it's easier to
    # use inside the template as `assigns[:key]`.
    content = EEx.eval_file(template_path, assigns: Enum.into(assigns, %{}))

    # 3. Send the result as HTML
    html(conn, content)
  end

  # ---- Step 28: Flash Messages & Redirect ----

  @doc """
  Redirects the client to a new path with a 302 response.

  Sets the `location` header and halts the connection so no further
  response body is sent. The session cookie (including any flash
  messages set via `put_flash/3`) will be encoded by the Cowboy adapter.
  """
  def redirect(%Conn{} = conn, to: path) do
    %Conn{
      conn
      | status: 302,
        resp_body: "",
        resp_headers:
          conn.resp_headers
          |> Map.put("location", path)
          |> Map.put("content-type", "text/html; charset=utf-8"),
        halted: true
    }
  end

  @doc """
  Stores a flash message in the session for the NEXT request.

  Flash messages survive exactly one redirect — they are set here in
  `conn.session["_flash"]`, encoded into the cookie by the adapter,
  and then popped out (moved to `conn.private.flash`) on the next
  request so they can be read once and then disappear.

  ## Example

      conn
      |> put_flash(:info, "User created!")
      |> redirect(to: "/")
  """
  def put_flash(%Conn{} = conn, key, message) do
    flash = Map.get(conn.session, "_flash", %{})
    new_flash = Map.put(flash, to_string(key), message)
    new_session = Map.put(conn.session, "_flash", new_flash)
    %Conn{conn | session: new_session}
  end

  @doc """
  Reads all flash messages from the CURRENT request.

  These were set by the previous request's `put_flash/3` call and
  popped from the session cookie by the adapter on this request.
  Returns an empty map if no flash messages exist.
  """
  def get_flash(%Conn{} = conn) do
    get_in(conn.private, [:flash]) || %{}
  end

  @doc """
  Reads a specific flash message by key (e.g. `:info` or `:error`).
  """
  def get_flash(%Conn{} = conn, key) do
    conn |> get_flash() |> Map.get(to_string(key))
  end

  # ---- End Step 28 ----

  @doc """
  Converts a fully-filled %Conn{} into a raw HTTP/1.1 response string.

  This is the bridge between the conn struct (Elixir data) and the
  raw bytes that get sent over the TCP socket.

  HTTP response format:
    HTTP/1.1 200 OK\r\n
    content-type: text/plain\r\n
    content-length: 5\r\n
    \r\n
    Hello
  """
  def send_resp(%Conn{} = conn) do
    status_line = "HTTP/1.1 #{conn.status} #{status_text(conn.status)}\r\n"

    # Add content-length automatically based on the body size
    headers =
      conn.resp_headers
      |> Map.put("content-length", to_string(byte_size(conn.resp_body)))
      |> Map.put("connection", "close")
      |> Enum.map(fn {k, v} -> "#{k}: #{v}\r\n" end)
      |> Enum.join()

    status_line <> headers <> "\r\n" <> conn.resp_body
  end

  @doc """
  Returns a hidden HTML input tag containing a masked CSRF token.
  """
  def csrf_token_tag(conn) do
    Ignite.CSRF.csrf_token_tag(conn)
  end

  defp status_text(200), do: "OK"
  defp status_text(201), do: "Created"
  defp status_text(302), do: "Found"
  defp status_text(400), do: "Bad Request"
  defp status_text(403), do: "Forbidden"
  defp status_text(404), do: "Not Found"
  defp status_text(422), do: "Unprocessable Entity"
  defp status_text(429), do: "Too Many Requests"
  defp status_text(500), do: "Internal Server Error"
  defp status_text(_),   do: "OK"

  @doc """
  Returns the CSP nonce for the connection.
  """
  def csp_nonce(conn) do
    Ignite.CSP.csp_nonce(conn)
  end

  @doc """
  Generates a script tag with the correct CSP nonce.
  """
  def csp_script_tag(conn, js_code) do
    Ignite.CSP.csp_script_tag(conn, js_code)
  end

  @doc """
  Returns a hashed path for a static asset.
  """
  def static_path(filename) do
    Ignite.Static.static_path(filename)
  end
end
