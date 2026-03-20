defmodule MyApp.ApiControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /api/status returns 200 and JSON" do
    conn = get(@router, "/api/status")
    json = json_response(conn, 200)
    assert json["status"] == "ok"
    assert json["framework"] == "Ignite"
  end

  test "POST /api/echo returns 200 and echoed data" do
    data = %{"message" => "hello ignite"}
    conn = 
      build_conn(:post, "/api/echo", data)
      |> put_content_type("application/json")
      |> dispatch(@router)

    json = json_response(conn, 200)
    assert json["echo"] == data
    assert json["method"] == "POST"
  end

  test "GET /health returns 200 and system metrics" do
    conn = get(@router, "/health")
    json = json_response(conn, 200)
    assert json["status"] == "ok"
    assert is_binary(json["uptime_human"])
    assert is_map(json["memory"])
  end
end
