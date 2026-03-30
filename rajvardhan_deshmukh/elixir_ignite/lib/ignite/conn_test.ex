defmodule Ignite.ConnTest do
  @moduledoc """
  Helpers for testing Ignite controllers and routes.

  These functions allow you to simulate HTTP requests and assert on the
  resulting %Ignite.Conn{} without needing to started a real HTTP server.
  """

  @doc """
  Builds a new connection struct with the given method, path, and params.
  """
  def build_conn(method, path, params \\ %{}) do
    %Ignite.Conn{
      method: method |> to_string() |> String.upcase(),
      path: path,
      params: params
    }
  end

  @doc """
  Dispatches the connection through the given router module.
  """
  def dispatch(conn, router) do
    router.call(conn)
  end

  @doc "Shortcut for GET requests"
  def get(router, path, params \\ %{}) do
    build_conn(:get, path, params) |> dispatch(router)
  end

  @doc "Shortcut for POST requests"
  def post(router, path, params \\ %{}) do
    build_conn(:post, path, params) |> dispatch(router)
  end

  @doc "Shortcut for PUT requests"
  def put(router, path, params \\ %{}) do
    build_conn(:put, path, params) |> dispatch(router)
  end

  @doc "Shortcut for PATCH requests"
  def patch(router, path, params \\ %{}) do
    build_conn(:patch, path, params) |> dispatch(router)
  end

  @doc "Shortcut for DELETE requests"
  def delete(router, path, params \\ %{}) do
    build_conn(:delete, path, params) |> dispatch(router)
  end

  @doc """
  Asserts that the response is plain text and has the expected status.
  Returns the response body.
  """
  def text_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/plain")
    conn.resp_body
  end

  @doc """
  Asserts that the response is HTML and has the expected status.
  Returns the response body.
  """
  def html_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/html")
    conn.resp_body
  end

  @doc """
  Asserts that the response is JSON, has the expected status, and
  returns the decoded JSON body.
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
  Extracts the redirect location from the response.
  Raises if no redirect was set.
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
  Initializes a session in the connection for testing purposes.
  Generates a CSRF token by default.
  """
  def init_test_session(%Ignite.Conn{} = conn, extra \\ %{}) do
    csrf_token = Ignite.CSRF.generate_token()
    session = Map.merge(%{"_csrf_token" => csrf_token}, extra)
    %Ignite.Conn{conn | session: session}
  end

  @doc """
  Masks the session's CSRF token and adds it to the params.
  Required for testing CSRF-protected POST requests.
  """
  def with_csrf(%Ignite.Conn{} = conn) do
    session_token = conn.session["_csrf_token"]

    unless session_token do
      raise "No CSRF token in session. Call init_test_session/2 before with_csrf/1."
    end

    masked = Ignite.CSRF.mask_token(session_token)
    %Ignite.Conn{conn | params: Map.put(conn.params, "_csrf_token", masked)}
  end

  @doc """
  Sets the content-type request header.
  Use "application/json" to bypass CSRF in tests.
  """
  def put_content_type(%Ignite.Conn{} = conn, content_type) do
    %Ignite.Conn{conn | req_headers: Map.put(conn.req_headers, "content-type", content_type)}
  end

  @doc """
  Adds a custom request header.
  """
  def put_req_header(%Ignite.Conn{} = conn, key, value) do
    %Ignite.Conn{conn | req_headers: Map.put(conn.req_headers, key, value)}
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
