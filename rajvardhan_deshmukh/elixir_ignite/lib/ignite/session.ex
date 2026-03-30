defmodule Ignite.Session do
  @moduledoc """
  Signed cookie-based session store for Ignite.

  Sessions are serialized with `:erlang.term_to_binary/1`, signed with
  `Plug.Crypto.MessageVerifier.sign/2`, and stored in a `_ignite_session`
  cookie. Tampering is detected by signature verification.

  This module is used by the Cowboy adapter to decode sessions on request
  and encode them on response, enabling flash messages and other
  cross-request state.
  """

  @default_secret "ignite-secret-key-change-in-prod-min-64-bytes-long-for-security!!"

  defp secret do
    Application.get_env(:elixir_ignite, :secret_key_base, @default_secret)
  end

  @cookie_name "_ignite_session"

  @doc "Returns the cookie name used for the session."
  def cookie_name, do: @cookie_name

  @doc """
  Encodes a session map into a signed cookie value.

  The map is serialized to binary and then signed with HMAC
  so any tampering will be detected on decode.
  """
  def encode(session) when is_map(session) do
    session
    |> :erlang.term_to_binary()
    |> Plug.Crypto.MessageVerifier.sign(secret())
  end

  @doc """
  Decodes and verifies a signed cookie value back into a session map.

  Returns `{:ok, map}` on success or `:error` if the signature is invalid.
  Uses the `:safe` flag on `binary_to_term` to prevent atom table
  exhaustion attacks.
  """
  def decode(nil), do: :error
  def decode(""), do: :error
  def decode(cookie_value) when is_binary(cookie_value) do
    case Plug.Crypto.MessageVerifier.verify(cookie_value, secret()) do
      {:ok, binary} ->
        {:ok, :erlang.binary_to_term(binary, [:safe])}
      :error ->
        :error
    end
  end

  @doc """
  Parses a raw `Cookie` header string into a map of `%{name => value}`.

  ## Example

      iex> Ignite.Session.parse_cookies("foo=bar; baz=qux")
      %{"foo" => "bar", "baz" => "qux"}
  """
  def parse_cookies(nil), do: %{}
  def parse_cookies(""), do: %{}
  def parse_cookies(cookie_header) when is_binary(cookie_header) do
    cookie_header
    |> String.split(";")
    |> Enum.into(%{}, fn pair ->
      case String.split(String.trim(pair), "=", parts: 2) do
        [key, value] -> {key, value}
        [key] -> {key, ""}
      end
    end)
  end

  @doc """
  Builds a full `Set-Cookie` header value from a session map.

  The cookie is HttpOnly (no JS access) and SameSite=Lax (basic CSRF protection).
  """
  def build_cookie_header(session) do
    value = encode(session)
    "#{@cookie_name}=#{value}; Path=/; HttpOnly; SameSite=Lax"
  end
end
