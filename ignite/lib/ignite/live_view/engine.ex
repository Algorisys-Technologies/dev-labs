defmodule Ignite.LiveView.Engine do
  @moduledoc """
  Splits rendered HTML into statics and dynamics for efficient updates.
  """

  @doc "Renders a view and returns {statics, dynamics} for mount."
  def render(view_module, assigns) do
    html = apply(view_module, :render, [assigns])
    # Wrap entire HTML as a single dynamic value
    {["", ""], [html]}
  end

  @doc "Renders and returns only the dynamics list for updates."
  def render_dynamics(view_module, assigns) do
    html = apply(view_module, :render, [assigns])
    [html]
  end
end
