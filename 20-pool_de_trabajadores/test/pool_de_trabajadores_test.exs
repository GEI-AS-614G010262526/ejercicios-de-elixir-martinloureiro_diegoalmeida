defmodule PoolDeTrabajadoresTest do
  use ExUnit.Case

  test "inicia y detiene el servidor correctamente" do
    {:ok, master} = Servidor.start(3)
    assert is_pid(master)
    assert Servidor.stop(master) == :ok
  end

  test "ejecuta un lote pequeño correctamente" do
    {:ok, master} = Servidor.start(3)

    jobs = [
      fn -> 1 + 1 end,
      fn -> Enum.sum(1..5) end,
      fn -> :math.sqrt(16) end
    ]

    assert Servidor.run_batch(master, jobs) == [2, 15, 4.0]
    Servidor.stop(master)
  end

  test "acepta lotes más grandes que el pool de trabajadores" do
    {:ok, master} = Servidor.start(3)

    jobs = Enum.map(1..10, fn i -> fn -> i * i end end)
    assert Servidor.run_batch(master, jobs) == Enum.map(1..10, &(&1 * &1))

    Servidor.stop(master)
  end

  test "mantiene el orden de resultados aunque los trabajos tarden mas o menos" do
    {:ok, master} = Servidor.start(2)

    jobs = [
      fn -> :timer.sleep(200); "A" end,
      fn -> "B" end,
      fn -> "C" end,
      fn -> :timer.sleep(100); "D" end
    ]

    assert Servidor.run_batch(master, jobs) == ["A", "B", "C", "D"]
    Servidor.stop(master)
  end

  test "puede ejecutar varios lotes seguidos" do
    {:ok, master} = Servidor.start(3)
    assert Servidor.run_batch(master, [fn -> "uno" end]) == ["uno"]
    assert Servidor.run_batch(master, [fn -> "dos" end, fn -> "tres" end]) == ["dos", "tres"]
    Servidor.stop(master)
  end
end
