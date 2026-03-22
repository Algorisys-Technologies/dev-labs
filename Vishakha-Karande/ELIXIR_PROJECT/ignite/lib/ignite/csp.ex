defmodule Ignite.CSP do
  @nonce_size 16

  def generate_nonce do
    @nonce_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def put_csp_headers(conn) do
    nonce = generate_nonce()

    %Ignite.Conn{
      conn
      | private: Map.put(conn.private, :csp_nonce, nonce),
        resp_headers: Map.put(conn.resp_headers, "content-security-policy", build_header(nonce))
    }
  end

  def csp_nonce(conn) do
    Map.get(conn.private, :csp_nonce, "")
  end

  def csp_script_tag(conn, js_code) do
    nonce = csp_nonce(conn)
    ~s(<script nonce="#{nonce}">#{js_code}</script>)
  end

  def build_header(nonce) do
    [
      "default-src 'self'",
      "script-src 'self' 'nonce-#{nonce}'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data:",
      "connect-src 'self' ws: wss:",
      "font-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ]
    |> Enum.join("; ")
  end
end
