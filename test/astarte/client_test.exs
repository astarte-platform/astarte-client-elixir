defmodule Astarte.ClientTest do
  use ExUnit.Case
  doctest Astarte.Client

  test "greets the world" do
    assert Astarte.Client.hello() == :world
  end
end
