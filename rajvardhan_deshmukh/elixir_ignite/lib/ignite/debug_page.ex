defmodule Ignite.DebugPage do
  @moduledoc """
  Renders a detailed debug error page for development or a generic 500 page for production.
  """

  def render(exception, stacktrace, %Ignite.Conn{} = conn) do
    # Don't show the debug page in production.
    if Application.get_env(:elixir_ignite, :env) == :prod do
      conn
    else
      render_dev(exception, stacktrace, conn)
    end
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
        body { font-family: system-ui, sans-serif; margin: 0; background: #f5f5f5; color: #333; }
        header { background: #e74c3c; color: #fff; padding: 24px 32px; }
        header h1 { font-size: 1.4em; margin: 0; }
        header pre { background: rgba(0,0,0,0.2); padding: 12px; border-radius: 6px; margin-top: 10px; white-space: pre-wrap; word-break: break-all; }
        nav { background: #fff; border-bottom: 2px solid #e0e0e0; padding: 0 32px; position: sticky; top: 0; z-index: 10; }
        .tab { background: none; border: none; padding: 16px 20px; cursor: pointer; font-size: 0.9em; outline: none; }
        .tab.active { color: #e74c3c; border-bottom: 3px solid #e74c3c; font-weight: 600; }
        .panel { display: none; padding: 24px 32px; }
        .panel.active { display: block; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th { text-align: left; padding: 8px 12px; background: #eee; border-bottom: 1px solid #ddd; }
        td { padding: 8px 12px; border-bottom: 1px solid #eee; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; }
        tr.app td { font-weight: 600; color: #2c3e50; }
        tr.dep td { color: #95a5a6; }
        h3 { margin-top: 0; color: #7f8c8d; border-bottom: 1px solid #ddd; padding-bottom: 8px; }
        .empty { color: #95a5a6; font-style: italic; }
      </style>
    </head>
    <body>
      <header>
        <h1>#{exception_type}</h1>
        <pre>#{message}</pre>
      </header>
      <nav>
        <button class="tab active" onclick="showTab(this, 'stacktrace')">Stacktrace</button>
        <button class="tab" onclick="showTab(this, 'request')">Request</button>
        <button class="tab" onclick="showTab(this, 'session')">Session</button>
      </nav>
      <div id="stacktrace" class="panel active">
        <table>
          <thead>
            <tr><th>Function</th><th>File:Line</th></tr>
          </thead>
          <tbody>#{trace_html}</tbody>
        </table>
      </div>
      <div id="request" class="panel">#{format_request(conn)}</div>
      <div id="session" class="panel">#{format_session(conn)}</div>
      <script>
        function showTab(btn, id) {
          document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          document.getElementById(id).classList.add('active');
          btn.classList.add('active');
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
    file = (Keyword.get(location, :file, ~c"") |> to_string()) || "unknown"
    line = Keyword.get(location, :line, "?")
    app_class = if app_frame?(file), do: "app", else: "dep"

    "<tr class=\"#{app_class}\"><td>#{html_escape(func)}</td><td>#{html_escape(file)}:#{line}</td></tr>"
  end

  defp app_frame?(file) do
    String.contains?(file, "lib/my_app") or String.contains?(file, "lib/ignite")
  end

  # --- Request tab ---

  defp format_request(nil), do: "<p class=\"empty\">Request context not available.</p>"

  defp format_request(conn) do
    headers_html =
      conn.req_headers
      |> Enum.sort()
      |> Enum.map_join("\n", fn {k, v} ->
        "<tr><td>#{html_escape(k)}</td><td>#{html_escape(v)}</td></tr>"
      end)

    params_html =
      if conn.params == %{} do
        "<p class=\"empty\">No parameters</p>"
      else
        rows =
          conn.params
          |> Enum.sort()
          |> Enum.map_join("\n", fn {k, v} ->
            "<tr><td>#{html_escape(to_string(k))}</td><td>#{html_escape(inspect(v))}</td></tr>"
          end)

        "<table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>#{rows}</tbody></table>"
      end

    """
    <h3>General</h3>
    <table>
      <tbody>
        <tr><td><strong>Method</strong></td><td>#{html_escape(conn.method)}</td></tr>
        <tr><td><strong>Path</strong></td><td>#{html_escape(conn.path)}</td></tr>
        <tr><td><strong>Status</strong></td><td>#{conn.status}</td></tr>
      </tbody>
    </table>
    <h3>Parameters</h3>
    #{params_html}
    <h3>Headers</h3>
    <table>
      <thead><tr><th>Header</th><th>Value</th></tr></thead>
      <tbody>#{headers_html}</tbody>
    </table>
    """
  end

  # --- Session tab ---

  defp format_session(nil), do: "<p class=\"empty\">Session not available.</p>"

  defp format_session(conn) do
    if conn.session == %{} do
      "<p class=\"empty\">Empty session</p>"
    else
      rows =
        conn.session
        |> Enum.sort()
        |> Enum.map_join("\n", fn {k, v} ->
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

  defp html_escape(other), do: html_escape(to_string(other))
end
