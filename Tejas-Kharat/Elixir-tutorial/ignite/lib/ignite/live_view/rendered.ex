defmodule Ignite.LiveView.Rendered do
  defstruct statics: [], dynamics: []

  def to_html(%__MODULE__{statics: statics, dynamics: dynamics}) do
    statics
    |> interleave(dynamics)
    |> IO.iodata_to_binary()
  end

  defp interleave([s | rest_s], [d | rest_d]) do
    [s, to_string(d) | interleave(rest_s, rest_d)]
  end

  defp interleave([s], []), do: [s]
end
