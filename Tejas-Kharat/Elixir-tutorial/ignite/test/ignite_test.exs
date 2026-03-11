defmodule IgniteTest do
  use ExUnit.Case
  doctest Ignite

  test "greets the world" do
    assert Ignite.hello() == :world
  end
end
