defmodule Ignite.LiveView.EExEngine do
  @moduledoc """
  A custom EEx engine that compiles templates into `%Ignite.LiveView.Rendered{}` structs.
  """
  @behaviour EEx.Engine

  # State: {statics_acc, dynamics_acc, current_pending_text}
  @impl true
  def init(_opts), do: {[], [], ""}

  @impl true
  def handle_begin(state), do: state

  @impl true
  def handle_end(state), do: state

  # Literal text -> hold in pending buffer until we hit an expression
  @impl true
  def handle_text(state, _meta, text) do
    {statics, dynamics, pending} = state
    {statics, dynamics, pending <> text}
  end

  # <%= expr %> -> flush pending text as a static, record the expression as a dynamic
  @impl true
  def handle_expr(state, "=", expr) do
    {statics, dynamics, pending} = state
    # We wrap the expression in to_string at runtime
    wrapped = quote do: to_string(unquote(expr))
    {[pending | statics], [wrapped | dynamics], ""}
  end

  # Just an expression without output (e.g. <% val = 1 %>) - append to dynamics
  # but with nil placeholder so indices align.
  @impl true
  def handle_expr(state, "", expr) do
    {statics, dynamics, pending} = state
    {[pending | statics], [expr | dynamics], ""}
  end

  # Build the final %Rendered{} struct
  @impl true
  def handle_body(state) do
    {statics_rev, dynamics_rev, trailing_text} = state
    
    # Reverse to get correct order and append trailing text to statics
    statics = Enum.reverse([trailing_text | statics_rev])
    dynamics_ast = Enum.reverse(dynamics_rev)

    quote do
      %Ignite.LiveView.Rendered{
        statics: unquote(statics),
        dynamics: unquote(dynamics_ast)
      }
    end
  end
end
