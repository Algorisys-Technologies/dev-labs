defmodule MyApp.WelcomeControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET / returns 200 with home page" do
    conn = get(@router, "/")
    body = html_response(conn, 200)
    assert body =~ "Ignite Framework"
    assert body =~ "Welcome to Ignite!"
  end

  test "GET /hello returns 200 with plain text" do
    conn = get(@router, "/hello")
    body = text_response(conn, 200)
    assert body == "Hello from the Controller!"
  end

  test "GET /non-existent returns 404" do
    conn = get(@router, "/oops")
    assert conn.status == 404
    assert conn.resp_body =~ "404"
  end

  test "responses include security headers" do
    conn = get(@router, "/")
    assert Map.has_key?(conn.resp_headers, "x-powered-by")
    assert Map.has_key?(conn.resp_headers, "content-security-policy")
  end
end
