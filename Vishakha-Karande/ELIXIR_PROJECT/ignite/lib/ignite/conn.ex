defmodule Ignite.Conn do
  defstruct [
    # Request fields (filled by the parser)
    method: nil,       # "GET", "POST", etc.
    path: nil,         # "/users/42"
    headers: %{},      # %{"host" => "localhost:4000", ...}
    params: %{},       # URL and body parameters (used later)

    # Response fields (filled by controllers)
    status: 200,
    resp_headers: %{"content-type" => "text/plain"},
    resp_body: "",

    # Control flow
    halted: false,     # When true, stops the middleware pipeline

    # Session and Cookies (Step 28)
    cookies: %{},       # Parsed request cookies (from "cookie" header)
    session: %{},       # Deserialized session data (from signed cookie)
    resp_cookies: [],   # Reserved for future use
    private: %{}        # Internal framework state (flash storage)
  ]
end
