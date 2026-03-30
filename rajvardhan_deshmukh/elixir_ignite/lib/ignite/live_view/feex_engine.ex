defmodule Ignite.LiveView.FEExEngine do
  @behaviour EEx.Engine

  @impl true
  def init(_opts) do
    # State: {reversed_statics, reversed_dynamics, pending_text_buffer}
    {[], [], ""}
  end

  @impl true
  def handle_begin(_state) do
    # Fresh sub-buffer for block body (if/for/case/cond)
    {[], [], ""}
  end

  @impl true
  def handle_end(state) do
    # Convert sub-buffer into AST that produces a string
    {statics_rev, dynamics_rev, trailing} = state
    statics = Enum.reverse([trailing | statics_rev])
    dynamics_ast = Enum.reverse(dynamics_rev)
    build_body_ast(statics, dynamics_ast)
  end

  @impl true
  def handle_text(state, _meta, text) do
    {statics, dynamics, pending} = state
    {statics, dynamics, pending <> text}
  end

  @impl true
  def handle_expr(state, "=", expr) do
    {statics, dynamics, pending} = state

    wrapped =
      if block_expr?(expr) do
        # Block expression (if/for/case/cond) written as <%= if ... do %>.
        # The body was compiled by handle_begin/handle_end and contains
        # already-escaped inner expressions. Don't escape again.
        quote do: Ignite.LiveView.FEExEngine.block_to_string(unquote(expr))
      else
        # Simple value expression: auto-escape HTML
        quote do: Ignite.LiveView.FEExEngine.escape(unquote(expr))
      end

    {[pending | statics], [wrapped | dynamics], ""}
  end

  def handle_expr(state, "", expr) do
    # Non-output block expression (<% if ... do %> without =)
    # Same as above but triggered via <% %> syntax.
    {statics, dynamics, pending} = state

    wrapped = quote do: Ignite.LiveView.FEExEngine.block_to_string(unquote(expr))

    {[pending | statics], [wrapped | dynamics], ""}
  end

  def handle_expr(state, _marker, _expr), do: state

  @impl true
  def handle_body(state) do
    {statics_rev, dynamics_rev, trailing} = state
    statics = Enum.reverse([trailing | statics_rev])
    dynamics_ast = Enum.reverse(dynamics_rev)

    quote do
      %Ignite.LiveView.Rendered{
        statics: unquote(statics),
        dynamics: unquote(dynamics_ast)
      }
    end
  end

  # --- AST analysis ---

  defp block_expr?({atom, _, args}) when atom in [:if, :unless, :case, :cond, :for] do
    is_list(args) and Enum.any?(args, fn
      [{:do, _} | _] -> true
      _ -> false
    end)
  end

  defp block_expr?(_), do: false

  # --- Runtime helpers ---

  @doc """
  Converts block expression results to strings.

  Handles the three return types from block expressions:
  - `nil` from `if` without `else` → empty string
  - `list` from `for` comprehension → joined string
  - anything else → converted to string
  """
  def block_to_string(nil), do: ""
  def block_to_string(list) when is_list(list), do: Enum.join(list)
  def block_to_string(val) when is_binary(val), do: val
  def block_to_string(val), do: to_string(val)

  @doc """
  Escapes HTML entities for safe rendering.
  """
  def escape({:safe, val}), do: to_string(val)
  def escape(nil), do: ""

  def escape(val) when is_binary(val) do
    val
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  def escape(%Ignite.LiveView.Rendered{statics: statics, dynamics: dynamics}) do
    interleave(statics, dynamics) |> IO.iodata_to_binary()
  end

  def escape(val), do: escape(to_string(val))

  defp build_body_ast([""], []), do: ""
  defp build_body_ast([s], []), do: s

  defp build_body_ast(statics, dynamics) do
    iodata = interleave(statics, dynamics)
    quote do: IO.iodata_to_binary(unquote(iodata))
  end

  defp interleave([s | rest_s], [d | rest_d]) do
    [s, d | interleave(rest_s, rest_d)]
  end

  defp interleave([s], []) do
    [s]
  end
end
