defmodule Ignite.HSTS do
  @moduledoc """
  HTTP Strict Transport Security (HSTS) plug for Ignite.

  When enabled, adds the `strict-transport-security` response header
  to tell browsers: "Only connect to this site over HTTPS for the next
  N seconds."
  """

  @default_max_age 31_536_000

  def put_hsts_header(conn) do
    if Application.get_env(:ignite, :hsts, false) do
      max_age = Application.get_env(:ignite, :hsts_max_age, @default_max_age)
      value = "max-age=#{max_age}; includeSubDomains"

      new_headers = Map.put(conn.resp_headers, "strict-transport-security", value)
      %Ignite.Conn{conn | resp_headers: new_headers}
    else
      conn
    end
  end
end
