defmodule Ignite.LiveView.FEExEngine do
  @moduledoc """
  EEx Engine for Flame EEx (~F).

  Supports:
  1. Auto HTML escaping of dynamic values.
  2. Block expressions (if, for, case, cond) via handle_begin/handle_end.
  """
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
        quote do
          case unquote(expr) do
            nil -> ""
            list when is_list(list) -> Enum.join(list)
            val -> to_string(val)
          end
        end
      else
        # Simple value expression: auto-escape HTML
        quote do: Ignite.LiveView.FEExEngine.escape(unquote(expr))
      end

    {[pending | statics], [wrapped | dynamics], ""}
  end

  def handle_expr(state, "", expr) do
    # Non-output block expression (<% if ... do %> without =)
    {statics, dynamics, pending} = state

    wrapped =
      quote do
        case unquote(expr) do
          nil -> ""
          list when is_list(list) -> Enum.join(list)
          val -> to_string(val)
        end
      end

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

  def escape(val), do: escape(to_string(val))

  # --- Private: AST builders ---

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
