defmodule Ignite.Controller do
  def text(conn, body, status \\ 200) do
    %Ignite.Conn{
      conn
      | status: status,
        resp_body: body,
        resp_headers: Map.put(conn.resp_headers, "content-type", "text/plain"),
        halted: true
    }
  end

  def html(conn, body, status \\ 200) do
    %Ignite.Conn{
      conn
      | status: status,
        resp_body: body,
        resp_headers: Map.put(conn.resp_headers, "content-type", "text/html; charset=utf-8"),
        halted: true
    }
  end

  def render(conn, template_name, assigns \\ []) do
    template_path = Path.join("templates", "#{template_name}.html.eex")
    content = EEx.eval_file(template_path, assigns: Enum.into(assigns, %{}))
    html(conn, content)
  end

  def send_resp(conn) do
    status_line = "HTTP/1.1 #{conn.status} #{status_text(conn.status)}\r\n"

    headers =
      conn.resp_headers
      |> Map.put("content-length", Integer.to_string(byte_size(conn.resp_body)))
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
