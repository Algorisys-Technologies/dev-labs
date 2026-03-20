defmodule Ignite.Session do
  @default_secret "ignite-secret-key-change-in-prod-min-64-bytes-long-for-security!!"
  @cookie_name "_ignite_session"

  # In production, set via config: config :ignite, :secret_key_base, "..."
  defp secret do
    Application.get_env(:ignite, :secret_key_base, @default_secret)
  end

  def cookie_name, do: @cookie_name

  def encode(session) when is_map(session) do
    session
    |> :erlang.term_to_binary()
    |> Plug.Crypto.MessageVerifier.sign(secret())
  end

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

  def build_cookie_header(session) do
    value = encode(session)
    "#{@cookie_name}=#{value}; Path=/; HttpOnly; SameSite=Lax"
  end
end
