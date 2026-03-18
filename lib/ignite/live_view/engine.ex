defmodule Ignite.LiveView.Engine do
  @moduledoc """
  Core engine for rendering and diffing LiveView templates.
  """
  alias Ignite.LiveView.Rendered
  alias Ignite.LiveView.Diff

  def render(view_module, assigns) do
    view_module.render(assigns) |> normalize()
  end

  # %Rendered{} from ~L sigil
  def normalize(%Rendered{} = r), do: r

  # Legacy string: entire HTML is one dynamic
  def normalize(html) when is_binary(html) do
    %Rendered{statics: ["", ""], dynamics: [html]}
  end

  @doc """
  Computes a sparse diff between old and new state.
  """
  def diff(old_rendered, new_rendered) do
    Diff.calculate(old_rendered, new_rendered)
  end
end
