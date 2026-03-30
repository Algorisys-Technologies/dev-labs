defmodule MyApp.ApiControllerTest do
  use ExUnit.Case
  import Ignite.ConnTest

  @router MyApp.Router

  test "GET /api/status returns 200 with JSON" do
    conn = get(@router, "/api/status")
    json = json_response(conn, 200)
    assert json["status"] == "ok"
    assert is_binary(json["elixir_version"])
  end

  test "GET /health returns 200 with system metrics" do
    conn = get(@router, "/health")
    json = json_response(conn, 200)
    assert json["status"] == "ok"
    assert is_number(json["uptime_seconds"])
    assert is_binary(json["elixir_version"])
  end
end
