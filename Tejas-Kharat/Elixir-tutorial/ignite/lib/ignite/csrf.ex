defmodule Ignite.CSRF do
  @token_size 32

  def generate_token do
    @token_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def get_token(conn) do
    conn.session["_csrf_token"] || generate_token()
  end

  def mask_token(token) do
    decoded = Base.url_decode64!(token, padding: false)
    mask = :crypto.strong_rand_bytes(byte_size(decoded))
    masked = xor_bytes(mask, decoded)
    Base.url_encode64(mask <> masked, padding: false)
  end

  def valid_token?(session_token, submitted_token)
      when is_binary(session_token) and is_binary(submitted_token) do
    with {:ok, decoded_session} <- Base.url_decode64(session_token, padding: false),
         {:ok, decoded_submitted} <- Base.url_decode64(submitted_token, padding: false) do
      size = byte_size(decoded_session)

      if byte_size(decoded_submitted) == size * 2 do
        <<mask::binary-size(size), masked::binary-size(size)>> = decoded_submitted
        unmasked = xor_bytes(mask, masked)
        Plug.Crypto.secure_compare(decoded_session, unmasked)
      else
        false
      end
    else
      _ -> false
    end
  end

  def valid_token?(_session, _submitted), do: false

  def csrf_token_tag(conn) do
    token = get_token(conn)
    masked = mask_token(token)
    ~s(<input type="hidden" name="_csrf_token" value="#{masked}">)
  end

  defp xor_bytes(a, b) do
    a_list = :binary.bin_to_list(a)
    b_list = :binary.bin_to_list(b)

    a_list
    |> Enum.zip(b_list)
    |> Enum.map(fn {x, y} -> Bitwise.bxor(x, y) end)
    |> :binary.list_to_bin()
  end
end
