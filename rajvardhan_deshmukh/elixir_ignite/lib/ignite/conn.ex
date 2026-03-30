defmodule Ignite.Conn do
  @moduledoc """
  The connection struct — the heart of every request/response in Ignite.

  This struct tracks the entire lifecycle of an HTTP request:
  - What came in (method, path, headers)
  - What's going out (status, response body, response headers)

  Every function in our framework receives a conn and returns a conn.
  This is the same pattern Phoenix uses with %Plug.Conn{}.
  """

  defstruct [
    # Request fields (filled by the parser)
    method: nil,
    path: nil,
    req_headers: %{},
    params: %{},

    # Cookie & Session fields (Step 28 — Flash Messages)
    cookies: %{},       # Parsed request cookies (from "cookie" header)
    session: %{},       # Deserialized session data (from signed cookie)
    resp_cookies: [],   # Reserved for future use
    private: %{},       # Internal framework state (flash storage)

    # Response fields (filled by controllers)
    status: 200,
    resp_headers: %{"content-type" => "text/plain"},
    resp_body: "",

    # Control flow
    halted: false
  ]
end
