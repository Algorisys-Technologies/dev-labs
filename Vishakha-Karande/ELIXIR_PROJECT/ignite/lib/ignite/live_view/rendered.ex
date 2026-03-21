defmodule Ignite.LiveView.Rendered do
  @moduledoc """
  A struct representing a compiled LiveView template.
  
  `statics` is a list of literal string parts.
  `dynamics` is a list of evaluated expressions (or other Rendered structs).
  """
  defstruct statics: [], dynamics: []
end
