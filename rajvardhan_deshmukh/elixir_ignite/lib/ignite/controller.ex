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
  Sends a plain text response.

  Sets the content-type to "text/plain" and stores the body in the conn.
  """
  def text(conn, body, status \\ 200) do
    %Conn{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/plain")
    }
  end

  @doc """
  Sends an HTML response.

  Sets the content-type to "text/html" and stores the body in the conn.
  """
  def html(conn, body, status \\ 200) do
    %Conn{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/html")
    }
  end

  @doc """
  Converts a fully-filled %Conn{} into a raw HTTP/1.1 response string.

  This is the bridge between the conn struct (Elixir data) and the
  raw bytes that get sent over the TCP socket.

  HTTP response format:
    HTTP/1.1 200 OK\\r\\n
    content-type: text/plain\\r\\n
    content-length: 5\\r\\n
    \\r\\n
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

  defp status_text(200), do: "OK"
  defp status_text(404), do: "Not Found"
  defp status_text(500), do: "Internal Server Error"
  defp status_text(_),   do: "OK"
end
