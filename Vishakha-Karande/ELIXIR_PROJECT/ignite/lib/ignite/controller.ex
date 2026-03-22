defmodule Ignite.Controller do
  def text(conn, body, status \\ 200) do
    %{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/plain"),
      halted: true
    }
  end

  def html(conn, body, status \\ 200) do
    %{conn |
      status: status,
      resp_body: body,
      resp_headers: Map.put(conn.resp_headers, "content-type", "text/html; charset=utf-8"),
      halted: true
    }
  end

  def render(conn, template, assigns \\ []) do
    template_path = Path.expand("templates/#{template}.html.eex")
    content = EEx.eval_file(template_path, assigns: Enum.into(assigns, %{}))
    html(conn, content)
  end

  def render_live(conn, module, params \\ %{}) do
    Ignite.LiveView.Static.render(conn, module, params)
  end

  def json(conn, data, status \\ 200) do
    %{conn |
      status: status,
      resp_body: Jason.encode!(data),
      resp_headers: Map.put(conn.resp_headers, "content-type", "application/json"),
      halted: true
    }
  end

  def static_path(filename) do
    Ignite.Static.static_path(filename)
  end

  def redirect(conn, to: path) do
    %{conn |
      status: 302,
      resp_body: "",
      resp_headers:
        conn.resp_headers
        |> Map.put("location", path)
        |> Map.put("content-type", "text/html; charset=utf-8"),
      halted: true
    }
  end

  def put_flash(conn, key, message) do
    flash = Map.get(conn.session, "_flash", %{})
    new_flash = Map.put(flash, to_string(key), message)
    new_session = Map.put(conn.session, "_flash", new_flash)
    %{conn | session: new_session}
  end

  def get_flash(conn) do
    get_in(conn.private, [:flash]) || %{}
  end

  def get_flash(conn, key) do
    conn |> get_flash() |> Map.get(to_string(key))
  end

  def csrf_token_tag(conn) do
    Ignite.CSRF.csrf_token_tag(conn)
  end

  def csp_nonce(conn) do
    Ignite.CSP.csp_nonce(conn)
  end

  def csp_script_tag(conn, js_code) do
    Ignite.CSP.csp_script_tag(conn, js_code)
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
  defp status_text(403), do: "Forbidden"
  defp status_text(404), do: "Not Found"
  defp status_text(429), do: "Too Many Requests"
  defp status_text(422), do: "Unprocessable Entity"
  defp status_text(500), do: "Internal Server Error"
  defp status_text(_),   do: "OK"
end
