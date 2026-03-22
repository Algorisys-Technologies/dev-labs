defmodule Ignite.LiveView.Diff do
  @moduledoc """
  Calculates the difference between two rendered structs.
  Returns a map compatible with the Step 24 sparse protocol.
  """

  # Initial render (Mount)
  def calculate(nil, new), do: serialize(new)
  
  # Update render (Diff)
  def calculate(old, new) do
    if old.statics == new.statics do
      diff_dynamics(old.dynamics, new.dynamics)
    else
      # If statics changed, re-send EVERYTHING
      serialize(new)
    end
  end

  def serialize(rendered) do
    # Convert dynamics list to a map with string indices
    payload = 
      rendered.dynamics
      |> Enum.with_index()
      |> Map.new(fn {val, idx} -> {to_string(idx), serialize_value(val)} end)

    Map.put(payload, :s, rendered.statics)
  end

  defp serialize_value(%Ignite.LiveView.Rendered{} = r), do: serialize(r)
  defp serialize_value(other), do: other

  defp diff_dynamics(old_dyn, new_dyn) do
    old_dyn
    |> Enum.zip(new_dyn)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {{old, new}, idx}, acc ->
      if old == new do
        acc
      else
        Map.put(acc, to_string(idx), serialize_value(new))
      end
    end)
  end
end
