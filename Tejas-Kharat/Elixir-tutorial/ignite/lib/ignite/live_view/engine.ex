defmodule Ignite.LiveView.Engine do
  @moduledoc """
  Optimized diffing engine that tracks individual dynamic expressions.
  """

  alias Ignite.LiveView.Rendered

  @doc "Renders a view and returns {statics, dynamics}."
  def render(view_module, assigns) do
    apply(view_module, :render, [assigns])
    |> normalize()
  end

  @doc "Computes a sparse diff between old and new dynamics."
  def diff(old_dynamics, new_dynamics) do
    changes =
      old_dynamics
      |> Enum.zip(new_dynamics)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{old, new}, idx}, acc ->
        if old == new, do: acc, else: Map.put(acc, Integer.to_string(idx), new)
      end)

    if map_size(changes) == length(new_dynamics) do
      new_dynamics
    else
      changes
    end
  end

  defp normalize(%Rendered{statics: statics, dynamics: dynamics}) do
    {statics, dynamics}
  end

  defp normalize(html) when is_binary(html) do
    {["", ""], [html]}
  end
end
