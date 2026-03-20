defmodule Ignite.ConnTest do
  @moduledoc """
  Helpers for testing Ignite controllers and routers.
  """

  def build_conn(method, path, params \\ %{}) do
    %Ignite.Conn{
      method: method |> to_string() |> String.upcase(),
      path: path,
      params: params
    }
  end

  def dispatch(conn, router), do: router.call(conn)

  def get(router, path, params \\ %{}) do
    build_conn(:get, path, params) |> dispatch(router)
  end

  def post(router, path, params \\ %{}) do
    build_conn(:post, path, params) |> dispatch(router)
  end

  def put(router, path, params \\ %{}) do
    build_conn(:put, path, params) |> dispatch(router)
  end

  def patch(router, path, params \\ %{}) do
    build_conn(:patch, path, params) |> dispatch(router)
  end

  def delete(router, path, params \\ %{}) do
    build_conn(:delete, path, params) |> dispatch(router)
  end

  def text_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/plain")
    conn.resp_body
  end

  def html_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "text/html")
    conn.resp_body
  end

  def json_response(conn, status) do
    assert_status!(conn, status)
    assert_content_type!(conn, "application/json")

    case Jason.decode(conn.resp_body) do
      {:ok, decoded} ->
        decoded

      {:error, _reason} ->
        raise "Expected valid JSON body, got decode error. Body: #{conn.resp_body}"
    end
  end

  def redirected_to(conn) do
    case Map.get(conn.resp_headers, "location") do
      nil ->
        raise "Expected response to have a location header (redirect), but none was set.\n" <>
                "Response status: #{conn.status}"

      location ->
        location
    end
  end

  def init_test_session(conn, extra \\ %{}) do
    csrf_token = Ignite.CSRF.generate_token()
    session = Map.merge(%{"_csrf_token" => csrf_token}, extra)
    %Ignite.Conn{conn | session: session}
  end

  def with_csrf(conn) do
    session_token = conn.session["_csrf_token"]

    unless session_token do
      raise "No CSRF token in session. Call init_test_session/2 before with_csrf/1."
    end

    masked = Ignite.CSRF.mask_token(session_token)
    %Ignite.Conn{conn | params: Map.put(conn.params, "_csrf_token", masked)}
  end

  def put_content_type(conn, content_type) do
    %Ignite.Conn{conn | headers: Map.put(conn.headers, "content-type", content_type)}
  end

  def put_req_header(conn, key, value) do
    %Ignite.Conn{conn | headers: Map.put(conn.headers, key, value)}
  end

  def get_flash(conn) do
    case get_in(conn.private, [:flash]) do
      nil -> conn.session["_flash"] || %{}
      f when f == %{} -> conn.session["_flash"] || %{}
      f -> f
    end
  end

  def get_flash(conn, key) do
    conn |> get_flash() |> Map.get(to_string(key))
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
