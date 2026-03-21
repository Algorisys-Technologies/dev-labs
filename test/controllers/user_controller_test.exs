defmodule MyApp.UserControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /users returns 200 and user list (JSON)" do
    conn = 
      build_conn(:get, "/users")
      |> put_req_header("accept", "application/json")
      |> dispatch(@router)

    data = json_response(conn, 200)
    assert is_list(data["users"])
  end

  test "POST /users with valid CSRF token succeeds" do
    conn =
      build_conn(:post, "/users", %{"user" => %{"name" => "Jose"}})
      |> init_test_session()
      |> with_csrf()
      |> dispatch(@router)
    
    # UserController redirects after create
    assert redirected_to(conn) == "/users"
  end

  test "POST /users without CSRF token returns 403" do
    conn =
      build_conn(:post, "/users", %{"user" => %{"name" => "Hacker"}})
      |> init_test_session()
      # missing with_csrf()
      |> dispatch(@router)
    
    html_response(conn, 403)
  end
end
