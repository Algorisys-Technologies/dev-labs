defmodule MyApp.UserControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /users returns 200 and list of users" do
    conn = get(@router, "/users")
    json = json_response(conn, 200)
    assert is_list(json["users"])
  end

  test "POST /users with valid CSRF token redirects to home" do
    username = "Jose-#{:erlang.unique_integer([:positive])}"
    params = %{"username" => username, "email" => "#{username}@example.com"}
    
    conn = 
      build_conn(:post, "/users", params)
      |> init_test_session()
      |> with_csrf()
      |> dispatch(@router)

    assert redirected_to(conn) == "/"
    assert get_flash(conn, :info) =~ "User '#{username}' created!"
  end

  test "POST /users without CSRF token returns 403" do
    params = %{"user" => %{"name" => "Hacker"}}
    
    conn = 
      build_conn(:post, "/users", params)
      |> dispatch(@router)

    assert conn.status == 403
    assert conn.resp_body =~ "403 Forbidden"
  end

  test "POST /users with invalid params redirects with error flash" do
    params = %{"username" => ""} # Name missing
    
    conn = 
      build_conn(:post, "/users", params)
      |> init_test_session()
      |> with_csrf()
      |> dispatch(@router)

    assert redirected_to(conn) == "/"
    assert get_flash(conn, :error) =~ "Failed to create user"
  end
end
