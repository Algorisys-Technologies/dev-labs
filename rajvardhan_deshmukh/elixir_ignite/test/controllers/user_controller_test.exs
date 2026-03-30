defmodule MyApp.UserControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /users returns 200 with JSON list" do
    conn = get(@router, "/users")
    json = json_response(conn, 200)
    assert is_list(json["users"])
  end

  test "POST /users with valid CSRF token creates user" do
    params = %{"username" => "testuser_#{System.unique_integer([:positive])}", "email" => "test@example.com"}
    
    conn =
      build_conn(:post, "/users", params)
      |> init_test_session()
      |> with_csrf()
      |> dispatch(@router)

    assert redirected_to(conn) == "/"
    assert conn.session["_flash"]["info"] =~ "created successfully"
  end

  test "POST /users without CSRF token returns 403" do
    params = %{"username" => "attacker"}
    
    conn = post(@router, "/users", params)
    
    assert_status!(conn, 403)
    assert conn.resp_body =~ "Forbidden"
  end

  test "POST /users with invalid params redirects and sets error flash" do
    # Username is missing
    params = %{"email" => "bad@example.com"}
    
    conn =
      build_conn(:post, "/users", params)
      |> init_test_session()
      |> with_csrf()
      |> dispatch(@router)

    assert redirected_to(conn) == "/"
    assert conn.session["_flash"]["error"] =~ "Failed to create user"
    assert conn.session["_flash"]["error"] =~ "can't be blank"
  end

  defp assert_status!(conn, expected) do
    if conn.status != expected do
      raise "Expected status #{expected}, got #{conn.status}"
    end
  end
end
