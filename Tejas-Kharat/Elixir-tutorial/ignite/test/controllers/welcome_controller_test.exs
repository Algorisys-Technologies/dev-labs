defmodule MyApp.WelcomeControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET / returns 200 and home page" do
    conn = get(@router, "/")
    body = html_response(conn, 200)
    assert body =~ "Welcome to Ignite!"
    assert conn.resp_headers["x-powered-by"] == "Ignite"
    assert conn.resp_headers["content-security-policy"] =~ "default-src 'self'"
  end

  test "GET /hello returns 200 and greeting" do
    conn = get(@router, "/hello")
    # Hello controller returns text, but our helper checks for text/plain
    body = text_response(conn, 200)
    assert body =~ "Hello from the Controller!"
  end

  test "GET /non-existent returns 404" do
    conn = get(@router, "/non-existent")
    assert conn.status == 404
    assert conn.resp_body =~ "404 - Not Found"
  end
end
