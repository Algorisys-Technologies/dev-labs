defmodule Ignite.LiveView.EExEngine do
  @behaviour EEx.Engine

  # Start with empty accumulators: {statics_rev, dynamics_rev, pending_text}
  def init(_opts), do: {[], [], ""}

  # Required callbacks — EEx.Engine requires these even if unused
  def handle_begin(state), do: state
  def handle_end(state), do: state

  # Literal text → append to pending buffer
  def handle_text(state, _meta, text) do
    {statics, dynamics, pending} = state
    {statics, dynamics, pending <> text}
  end

  # <%= expr %> → flush pending text as a static, record the expression
  def handle_expr(state, "=", expr) do
    {statics, dynamics, pending} = state
    wrapped = quote do: to_string(unquote(expr))
    {[pending | statics], [wrapped | dynamics], ""}
  end

  # <% expr %> (non-output) — not supported in ~L, silently ignored
  def handle_expr(state, _marker, _expr), do: state

  # Final step → build the %Rendered{} struct
  def handle_body(state) do
    {statics_rev, dynamics_rev, trailing_text} = state
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
