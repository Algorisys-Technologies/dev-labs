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
    halted: false      # When true, stops the middleware pipeline
  ]
end
