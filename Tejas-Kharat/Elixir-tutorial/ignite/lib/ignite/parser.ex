defmodule Ignite.Parser do
  alias Ignite.Conn

  def parse(client_socket) do
    {method, path} = read_request_line(client_socket)
    headers = read_headers(client_socket)

    # Parse body for POST/PUT/PATCH requests
    body_params = read_body(client_socket, headers)

    %Conn{
      method: to_string(method),
      path: to_string(path),
      headers: headers,
      params: body_params
    }
  end

  defp read_request_line(socket) do
    {:ok, {:http_request, method, {:abs_path, path}, _version}} = :gen_tcp.recv(socket, 0)
    {method, path}
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

  defp read_body(socket, headers) do
    case Map.get(headers, "content-length") do
      nil -> %{}
      length_str ->
        content_length = length_str |> to_string() |> String.to_integer()
        :inet.setopts(socket, packet: :raw)

        case :gen_tcp.recv(socket, content_length) do
          {:ok, body} -> parse_body(to_string(body), Map.get(headers, "content-type", "") |> to_string())
          _ -> %{}
        end
    end
  end

  # Parses "username=jose&password=secret" into %{"username" => "jose", ...}
  defp parse_body(body, "application/x-www-form-urlencoded" <> _) do
    URI.decode_query(body)
  end

  # Unknown content type — return body as-is under "_body" key
  defp parse_body(body, _content_type) do
    %{"_body" => body}
  end
end
