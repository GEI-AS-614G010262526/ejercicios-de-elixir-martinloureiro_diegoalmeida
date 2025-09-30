defmodule EratostenesTest do
  use ExUnit.Case

  test "primos hasta 10" do
    assert Eratostenes.primos(10) == [2, 3, 5, 7]
  end

  test "primos hasta 100" do
    assert Eratostenes.primos(100) == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
  end

  test "primos hasta 1" do
    assert Eratostenes.primos(1) == []
  end

  test "primos hasta 2" do
    assert Eratostenes.primos(2) == [2]
  end
end