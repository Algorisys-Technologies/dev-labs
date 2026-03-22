defmodule MyApp.ApiControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /api/status returns 200 and status ok" do
    conn = get(@router, "/api/status")
    data = json_response(conn, 200)
    assert data["status"] == "ok"
    assert data["framework"] == "Ignite"
  end

  test "POST /api/echo returns 200 and echoes params" do
    params = %{"hello" => "world"}
    conn = 
      build_conn(:post, "/api/echo", params)
      |> put_content_type("application/json")
      |> dispatch(@router)

    data = json_response(conn, 200)
    assert data["echo"] == params
  end

  test "GET /health returns 200 and system metrics" do
    conn = get(@router, "/health")
    data = json_response(conn, 200)
    assert data["status"] == "ok"
    assert is_number(data["uptime_seconds"])
    assert is_map(data["memory"])
  end
end
