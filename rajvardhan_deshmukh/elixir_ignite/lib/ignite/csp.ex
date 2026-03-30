defmodule Ignite.CSP do
  @moduledoc """
  Logic for Content Security Policy (CSP) headers and nonces.
  """

  @nonce_size 16

  @doc """
  Generates a random 16-byte nonce and base64url encodes it.
  """
  def generate_nonce do
    @nonce_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Generates a nonce, stores it in `conn.private`, and adds the CSP header.
  """
  def put_csp_headers(%Ignite.Conn{} = conn) do
    nonce = generate_nonce()

    %Ignite.Conn{
      conn
      | private: Map.put(conn.private, :csp_nonce, nonce),
        resp_headers: Map.put(conn.resp_headers, "content-security-policy", build_header(nonce))
    }
  end

  @doc """
  Reads the CSP nonce from the connection.
  """
  def csp_nonce(%Ignite.Conn{} = conn) do
    Map.get(conn.private, :csp_nonce, "")
  end

  @doc """
  Generates a script tag with the correct CSP nonce.
  """
  def csp_script_tag(%Ignite.Conn{} = conn, js_code) do
    nonce = csp_nonce(conn)
    ~s(<script nonce="#{nonce}">#{js_code}</script>)
  end

  @doc """
  Constructs the CSP header string with the provided nonce.
  """
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
