defmodule Ignite.Parser do
  alias Ignite.Conn

  def parse(client_socket) do
    case read_request_line(client_socket) do
      {:error, _reason} = err ->
        err

      {method, path} ->
        headers = read_headers(client_socket)

        %Conn{
          method: to_string(method),   # :GET → "GET"
          path: to_string(path),       # ~c"/" → "/"
          headers: headers             # %{"host" => "localhost:4000"}
        }
    end
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
