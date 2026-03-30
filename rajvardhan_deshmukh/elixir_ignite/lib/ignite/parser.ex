defmodule Ignite.Parser do
  @moduledoc """
  Parses raw HTTP data from a TCP socket into an %Ignite.Conn{} struct.

  This module bridges the gap between raw network data and structured
  Elixir data that the rest of our framework can work with.
  """

  alias Ignite.Conn

  @doc """
  Reads an HTTP request from a client socket and returns an %Ignite.Conn{}.

  Uses Erlang's built-in HTTP parser (via `packet: :http` on the socket)
  to read the request line and headers one at a time.
  """
  def parse(client_socket) do
    {method, path} = read_request_line(client_socket)
    headers = read_headers(client_socket)

    # New: Read and parse the request body
    params = read_body(client_socket, headers)

    %Conn{
      method: to_string(method),
      path: to_string(path),
      req_headers: headers,
      params: params
    }
  end

  # Reads the first line of the HTTP request.
  # Example: "GET /hello HTTP/1.1" becomes {"GET", "/hello"}
  defp read_request_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, {:http_request, method, {:abs_path, path}, _version}} ->
        {to_string(method), to_string(path)}

      {:error, :closed} ->
        # Client disconnected before sending a full request — just stop silently
        throw(:closed)

      {:error, reason} ->
        throw(reason)
    end
  end

  # Reads headers one at a time until we hit the blank line
  # that marks the end of headers (:http_eoh = "end of headers").
  # Returns a map like %{"host" => "localhost:4000", "user-agent" => "..."}
  defp read_headers(socket, acc \\ %{}) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, :http_eoh} ->
        acc

      {:ok, {:http_header, _, name, _, value}} ->
        # Normalize header names to lowercase strings
        # and ensure values are strings (not charlists).
        key = name |> to_string() |> String.downcase()
        val = to_string(value)
        read_headers(socket, Map.put(acc, key, val))
    end
  end

  # Reads the request body if a content-length header is present.
  defp read_body(socket, headers) do
    case Map.get(headers, "content-length") do
      nil ->
        %{}

      length_str ->
        content_length = String.to_integer(length_str)

        # To read the raw body, we must switch the socket from :http
        # parsing mode back to :raw byte mode.
        :inet.setopts(socket, packet: :raw)

        case :gen_tcp.recv(socket, content_length) do
          {:ok, body} ->
            parse_body(body, Map.get(headers, "content-type", ""))

          _ ->
            %{}
        end
    end
  end

  # Parses the body based on the Content-Type header.
  # For now, we only support form data (application/x-www-form-urlencoded).
  defp parse_body(body, "application/x-www-form-urlencoded" <> _) do
    URI.decode_query(body)
  end

  defp parse_body(_body, _content_type) do
    %{}
  end
end
