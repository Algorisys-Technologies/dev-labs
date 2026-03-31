defmodule Ignite.Parser do
  alias Ignite.Conn

  def parse(client_socket) do
    case read_request_line(client_socket) do
      {:error, _reason} = err ->
        err

      {method, path} ->
        headers = read_headers(client_socket)

        # Read body if Content-Length is present
        content_length = Map.get(headers, "content-length", "0") |> String.to_integer()
        
        {body, params} = 
          if content_length > 0 do
            # We must switch the socket back to raw binary mode to read the body
            :inet.setopts(client_socket, packet: :raw)
            {:ok, raw_body} = :gen_tcp.recv(client_socket, content_length)
            # Switch back to HTTP packet mode for the next request
            :inet.setopts(client_socket, packet: :http)
            
            content_type = Map.get(headers, "content-type", "")
            parsed_params = parse_body(raw_body, content_type)
            {raw_body, parsed_params}
          else
            {"", %{}}
          end

        %Conn{
          method: to_string(method),   # :GET → "GET"
          path: to_string(path),       # ~c"/" → "/"
          headers: headers,            # %{"host" => "localhost:4000"}
          params: params
        }
    end
  end

  defp parse_body(body, "application/json" <> _) when byte_size(body) > 0 do
    case Jason.decode(body) do
      {:ok, parsed} when is_map(parsed) -> parsed
      {:ok, parsed} -> %{"_json" => parsed}
      {:error, _} -> %{"_body" => body}
    end
  end

  defp parse_body(body, "application/x-www-form-urlencoded" <> _) do
    URI.decode_query(body)
  end

  defp parse_body(body, _content_type) do
    %{"_body" => body}
  end

  defp read_request_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, {:http_request, method, {:abs_path, path}, _}} ->
        {method, path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_headers(socket, acc \\ %{}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, :http_eoh} ->
        acc

      {:ok, {:http_header, _, name, _, value}} ->
        key = name |> to_string() |> String.downcase()
        read_headers(socket, Map.put(acc, key, value))
    end
  end
end
