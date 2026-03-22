defmodule Ignite.Websocket do
  import Bitwise

  @doc "Encodes a string into a WebSocket text frame."
  def encode(payload) do
    len = byte_size(payload)
    header = binary_header(len)
    header <> payload
  end

  defp binary_header(len) when len <= 125, do: <<0x81, len>>
  defp binary_header(len) when len <= 65535, do: <<0x81, 126, len::16>>
  defp binary_header(len), do: <<0x81, 127, len::64>>

  @doc "Decodes a WebSocket frame. Returns {:ok, payload, rest} or {:error, reason}."
  def decode(<<fin::1, _rsv::3, opcode::4, masked::1, payload_len::7, rest::binary>>) do
    # Only support text (1) or closure (8) for now
    case {opcode, masked} do
      {8, _} -> {:close, nil}
      {1, 1} -> decode_payload(payload_len, rest)
      _ -> {:error, "Unsupported opcode or unmasked client frame"}
    end
  end
  def decode(_), do: {:incomplete, nil}

  defp decode_payload(len, <<mask::32, data::binary>>) when len <= 125 do
    <<payload::binary-size(len), rest::binary>> = data
    {:ok, unmask(payload, mask, ""), rest}
  end

  defp decode_payload(126, <<len::16, mask::32, data::binary>>) do
    <<payload::binary-size(len), rest::binary>> = data
    {:ok, unmask(payload, mask, ""), rest}
  end

  defp decode_payload(127, <<len::64, mask::32, data::binary>>) do
    <<payload::binary-size(len), rest::binary>> = data
    {:ok, unmask(payload, mask, ""), rest}
  end

  defp unmask(<<byte::8, rest::binary>>, mask, acc) do
    # Circular shift mask
    unmasked_byte = bxor(byte, (mask >>> 24))
    new_mask = ((mask <<< 8) &&& 0xFFFFFFFF) ||| (mask >>> 24)
    unmask(rest, new_mask, acc <> <<unmasked_byte>>)
  end
  defp unmask(<<>>, _, acc), do: acc
end
