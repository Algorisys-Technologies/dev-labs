defmodule MyApp.WelcomeControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET / returns 200 and Welcome message" do
    conn = get(@router, "/")
    body = html_response(conn, 200)
    assert body =~ "Welcome to Ignite!"
  end

  test "GET /hello returns 200 and Hello message" do
    conn = get(@router, "/hello")
    body = text_response(conn, 200)
    assert body =~ "Hello from the Controller!"
  end

  test "GET /nonexistent returns 404" do
    conn = get(@router, "/nonexistent")
    body = text_response(conn, 404)
    assert body =~ "404 - Not Found"
  end

  test "Response includes X-Powered-By header" do
    conn = get(@router, "/")
    assert Map.get(conn.resp_headers, "x-powered-by") == "Ignite"
  end

  test "Response includes CSP headers" do
    conn = get(@router, "/")
    assert Map.has_key?(conn.resp_headers, "content-security-policy")
  end
end
