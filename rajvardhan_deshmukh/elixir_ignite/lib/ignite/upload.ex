defmodule Ignite.Upload do
  @moduledoc """
  Represents a file uploaded via an HTTP multipart request.
  """
  defstruct [:path, :filename, :content_type]
end
