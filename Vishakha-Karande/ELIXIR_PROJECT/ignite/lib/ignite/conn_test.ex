defmodule Ignite.ConnTest do
  @moduledoc """
  Helpers for testing Ignite controllers and routers.

  Allows building connections and dispatching them through a router
  without a running HTTP server.
  """

  @doc """
  Builds a new %Ignite.Conn{} for testing.
  """
  def build_conn(method, path, params \\ %{}) do
    %Ignite.Conn{
      method: method |> to_string() |> String.upcase(),
      path: path,
      params: params
    }
  end

  @doc """
  Dispatches a connection through the given router.
  """
  def dispatch(conn, router), do: router.call(conn)

  # Convenience helpers for common methods
  def get(router, path, params \\ %{}), do: build_conn(:get, path, params) |> dispatch(router)
  def post(router, path, params \\ %{}), do: build_conn(:post, path, params) |> dispatch(router)
  def put(router, path, params \\ %{}), do: build_conn(:put, path, params) |> dispatch(router)
  def patch(router, path, params \\ %{}), do: build_conn(:patch, path, params) |> dispatch(router)
  def delete(router, path, params \\ %{}), do: build_conn(:delete, path, params) |> dispatch(router)

  @doc """
  Asserts that the response body is plain text and the status matches.
  """
  def text_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/plain")
    conn.resp_body
  end

  @doc """
  Asserts that the response body is HTML and the status matches.
  """
  def html_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/html")
    conn.resp_body
  end

  @doc """
  Asserts that the response body is JSON and the status matches. Returns decoded data.
  """
  def json_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "application/json")

    case Jason.decode(conn.resp_body) do
      {:ok, decoded} ->
        decoded

      {:error, reason} ->
        raise "Expected valid JSON body, got decode error: #{inspect(reason)}\n\nBody: #{conn.resp_body}"
    end
  end

  @doc """
  Returns the redirect location from the response.
  """
  def redirected_to(conn) do
    case Map.get(conn.resp_headers, "location") do
      nil ->
        raise "Expected response to have a location header (redirect), but none was set.\n" <>
                "Response status: #{conn.status}"

      location ->
        location
    end
  end

  @doc """
  Initializes a session in the connection for testing, including a CSRF token.
  """
  def init_test_session(conn, extra \\ %{}) do
    csrf_token = Ignite.CSRF.generate_token()
    session = Map.merge(%{"_csrf_token" => csrf_token}, extra)
    %Ignite.Conn{conn | session: session}
  end

  @doc """
  Adds a masked CSRF token to the connection parameters.
  """
  def with_csrf(conn) do
    session_token = conn.session["_csrf_token"]

    unless session_token do
      raise "No CSRF token in session. Call init_test_session/2 before with_csrf/1."
    end

    masked = Ignite.CSRF.mask_token(session_token)
    %Ignite.Conn{conn | params: Map.put(conn.params, "_csrf_token", masked)}
  end

  @doc """
  Sets the content-type header for the request.
  """
  def put_content_type(conn, content_type) do
    %Ignite.Conn{conn | headers: Map.put(conn.headers, "content-type", content_type)}
  end

  @doc """
  Sets an arbitrary request header.
  """
  def put_req_header(conn, key, value) do
    %Ignite.Conn{conn | headers: Map.put(conn.headers, key, value)}
  end

  # --- Private Assertion Helpers ---

  defp assert_status!(conn, expected) do
    actual = conn.status

    if actual != expected do
      raise "Expected response status #{expected}, got #{actual}.\n\nBody: #{String.slice(conn.resp_body, 0, 500)}"
    end
  end

  defp assert_content_type!(conn, expected) do
    actual = Map.get(conn.resp_headers, "content-type", "")

    unless String.starts_with?(actual, expected) do
      raise "Expected content-type starting with #{inspect(expected)}, got #{inspect(actual)}."
    end
  end
end
