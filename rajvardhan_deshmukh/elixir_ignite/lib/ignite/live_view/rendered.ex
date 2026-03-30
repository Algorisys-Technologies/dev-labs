defmodule Ignite.LiveView.Rendered do
  @moduledoc """
  A struct representing a rendered LiveView template.
  
  `statics` is a list of static HTML strings.
  `dynamics` is a list of dynamic values (results of <%= %> expressions).
  """
  defstruct statics: [], dynamics: []
end
