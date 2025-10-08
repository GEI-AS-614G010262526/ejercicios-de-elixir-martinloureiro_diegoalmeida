defmodule EratostenesPipeTest do
  use ExUnit.Case

  test "primos hasta 10" do
    assert EratostenesPipe.primos(10) == [2, 3, 5, 7]
  end

  test "primos hasta 100" do
    assert EratostenesPipe.primos(100) == [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
  end

  test "cantidad de primos hasta 10000" do
    assert length(EratostenesPipe.primos(10_000)) == 1229
  end

  test "cantidad de primos hasta 100000" do
    assert length(EratostenesPipe.primos(100_000)) == 9592
  end

  test "primos hasta 1" do
    assert EratostenesPipe.primos(1) == []
  end

  test "primos hasta 2" do
    assert EratostenesPipe.primos(2) == [2]
  end
end