defmodule Ignite.DebugPage do
  def render(exception, stacktrace, conn) do
    if Application.get_env(:ignite, :env) == :prod do
      render_prod()
    else
      render_dev(exception, stacktrace, conn)
    end
  end

  defp render_prod do
    """
    <!DOCTYPE html>
    <html>
    <head><title>500 — Internal Server Error</title></head>
    <body style="font-family: system-ui; max-width: 600px; margin: 80px auto; text-align: center;">
      <h1 style="color: #e74c3c;">500 — Internal Server Error</h1>
      <p>Something went wrong. Please try again later.</p>
      <p><a href="/">Back to Home</a></p>
    </body>
    </html>
    """
  end

  defp render_dev(exception, stacktrace, conn) do
    exception_type = exception.__struct__ |> inspect() |> html_escape()
    message = Exception.message(exception) |> html_escape()
    trace_html = Enum.map_join(stacktrace, "\n", &format_entry/1)

    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{exception_type} — Ignite Debug</title>
      <style>
        body { font-family: system-ui, sans-serif; margin: 0; background: #f5f5f5; }
        header { background: #e74c3c; color: #fff; padding: 24px 32px; }
        header h1 { font-size: 1.4em; margin: 0; }
        header pre { background: rgba(0,0,0,0.2); padding: 12px; border-radius: 6px; margin-top: 10px; white-space: pre-wrap; }
        nav { background: #fff; border-bottom: 2px solid #e0e0e0; padding: 0 32px; display: flex; }
        .tab { background: none; border: none; padding: 12px 20px; cursor: pointer; font-size: 14px; color: #666; }
        .tab.active { color: #e74c3c; border-bottom: 3px solid #e74c3c; font-weight: 600; }
        .panel { display: none; padding: 24px 32px; background: #fff; min-height: 400px; }
        .panel.active { display: block; }
        table { width: 100%; border-collapse: collapse; }
        th { text-align: left; background: #f9f9f9; padding: 10px; border-bottom: 2px solid #eee; }
        td { padding: 8px 10px; border-bottom: 1px solid #eee; font-family: monospace; font-size: 13px; }
        tr.app td { font-weight: 600; color: #333; }
        tr.dep td { color: #999; }
        h3 { margin-top: 0; border-bottom: 1px solid #eee; padding-bottom: 10px; }
        .empty { color: #999; font-style: italic; }
      </style>
    </head>
    <body>
      <header><h1>#{exception_type}</h1><pre>#{message}</pre></header>
      <nav>
        <button id="tab-stacktrace" class="tab active" onclick="showTab('stacktrace')">Stacktrace</button>
        <button id="tab-request" class="tab" onclick="showTab('request')">Request</button>
        <button id="tab-session" class="tab" onclick="showTab('session')">Session</button>
      </nav>
      <section id="stacktrace" class="panel active">
        <table>
          <thead><tr><th>Function</th><th>File:Line</th></tr></thead>
          <tbody>#{trace_html}</tbody>
        </table>
      </section>
      <section id="request" class="panel">#{format_request(conn)}</section>
      <section id="session" class="panel">#{format_session(conn)}</section>
      <script>
        function showTab(id) {
          document.querySelectorAll('.panel').forEach(function(p) { p.classList.remove('active'); });
          document.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
          document.getElementById(id).classList.add('active');
          document.getElementById('tab-' + id).classList.add('active');
        }
      </script>
    </body>
    </html>
    """
  end

  # --- Stacktrace ---

  defp format_entry({mod, fun, arity, location}) do
    arity_val = if is_list(arity), do: length(arity), else: arity
    func = "#{inspect(mod)}.#{fun}/#{arity_val}"
    file = Keyword.get(location, :file, ~c"") |> to_string()
    line = Keyword.get(location, :line, "?")
    app_class = if app_frame?(file), do: "app", else: "dep"

    "<tr class=\"#{app_class}\"><td>#{html_escape(func)}</td><td>#{html_escape(file)}:#{line}</td></tr>"
  end

  defp app_frame?(file) do
    String.starts_with?(file, "lib/my_app") or String.starts_with?(file, "lib/ignite")
  end

  # --- Request tab ---

  defp format_request(nil), do: "<p>Request context not available.</p>"

  defp format_request(conn) do
    headers_html =
      conn.headers
      |> Enum.map_join("\n", fn {k, v} ->
        "<tr><td>#{html_escape(k)}</td><td>#{html_escape(v)}</td></tr>"
      end)

    params_html =
      if conn.params == %{} do
        "<p class=\"empty\">No parameters</p>"
      else
        rows =
          Enum.map_join(conn.params, "\n", fn {k, v} ->
            "<tr><td>#{html_escape(to_string(k))}</td><td>#{html_escape(inspect(v))}</td></tr>"
          end)

        "<table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>#{rows}</tbody></table>"
      end

    """
    <h3>Request Information</h3>
    <table style="margin-bottom: 20px;">
      <tbody>
        <tr><td><strong>Method</strong></td><td>#{html_escape(conn.method)}</td></tr>
        <tr><td><strong>Path</strong></td><td>#{html_escape(conn.path)}</td></tr>
      </tbody>
    </table>
    <h3>Parameters</h3>
    #{params_html}
    <h3 style="margin-top: 30px;">Headers</h3>
    <table>
      <thead><tr><th>Header</th><th>Value</th></tr></thead>
      <tbody>#{headers_html}</tbody>
    </table>
    """
  end

  # --- Session tab ---

  defp format_session(nil), do: "<p>Session not available.</p>"

  defp format_session(conn) do
    if conn.session == %{} do
      "<p class=\"empty\">Empty session</p>"
    else
      rows =
        Enum.map_join(conn.session, "\n", fn {k, v} ->
          "<tr><td>#{html_escape(to_string(k))}</td><td>#{html_escape(inspect(v))}</td></tr>"
        end)

      """
      <h3>Session Data</h3>
      <table>
        <thead><tr><th>Key</th><th>Value</th></tr></thead>
        <tbody>#{rows}</tbody>
      </table>
      """
    end
  end

  # --- HTML escaping ---

  defp html_escape(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
