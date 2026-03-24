defmodule Ignite.LiveView.FEExEngine do
  @moduledoc """
  EEx Engine for Flame EEx (~F).

  Supports:
  1. Auto HTML escaping of dynamic values.
  2. Block expressions (if, for, case, cond) via handle_begin/handle_end.
  3. Nested ~F templates (Rendered structs) rendered safely as HTML strings.

  IMPORTANT: escape/1 always returns a String.t(), never a tuple.
  This ensures safe use inside IO.iodata_to_binary in nested blocks.
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
        # Block expression (if/for/case/cond) - body already built by handle_end.
        # The body returns a string, so just cast it safely.
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
        _ = unquote(expr)
        ""
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

  @doc """
  Escapes a value for safe HTML insertion. ALWAYS returns a String (binary).
  Handles: Rendered structs, {:safe, val} tuples, lists, nil, and binaries.
  """
  def escape(%Ignite.LiveView.Rendered{} = rendered) do
    # dynamics inside a Rendered struct are already-escaped strings from the
    # inner ~F template  — do NOT call escape/1 on them again (double-escape).
    Enum.zip(rendered.statics, rendered.dynamics ++ [""])
    |> Enum.map(fn {s, d} -> s <> to_string(d) end)
    |> Enum.join()
  end

  def escape(list) when is_list(list) do
    list |> Enum.map(&escape/1) |> Enum.join()
  end

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
