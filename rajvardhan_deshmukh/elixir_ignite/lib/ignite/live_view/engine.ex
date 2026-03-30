defmodule Ignite.LiveView.Engine do
  @moduledoc """
  Splits rendered HTML into statics (unchanging parts) and dynamics
  (variable values) for efficient over-the-wire updates.

  Instead of sending full HTML on every update, we:
  1. On mount: send both statics and dynamics → {s: [...], d: [...]}
  2. On event: send only dynamics → {d: [...]}

  The frontend zips statics + dynamics to reconstruct the full HTML.

  ## Example

      Template: "<h1>Count: \#{count}</h1><p>Hello</p>"

      Statics:  ["<h1>Count: ", "</h1><p>Hello</p>"]
      Dynamics: ["42"]

      Reconstructed: "<h1>Count: 42</h1><p>Hello</p>"
  """

  @doc """
  Renders a LiveView module and returns {statics, dynamics}.

  Statics are extracted once (they never change between renders).
  Dynamics are the interpolated values that change on each render.
  """
  def render(view_module, assigns) do
    # Get the rendered result (either a string or a %Rendered{} struct)
    result = apply(view_module, :render, [assigns])

    # Normalize to {statics, dynamics}
    normalize(result)
  end

  @doc """
  Renders and returns only the dynamic values (for updates).
  """
  def render_dynamics(view_module, assigns) do
    case apply(view_module, :render, [assigns]) do
      %Ignite.LiveView.Rendered{dynamics: dynamics} -> dynamics
      html when is_binary(html) -> [html]
    end
  end

  # Normalize %Rendered{} to {statics, dynamics}
  defp normalize(%Ignite.LiveView.Rendered{statics: statics, dynamics: dynamics}) do
    {statics, dynamics}
  end

  # Backward compatibility: treat entire HTML as one dynamic chunk
  defp normalize(html) when is_binary(html) do
    {["", ""], [html]}
  end
end
