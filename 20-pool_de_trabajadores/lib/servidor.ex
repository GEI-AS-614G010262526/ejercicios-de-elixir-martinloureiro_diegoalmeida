defmodule Servidor do
  @moduledoc """
  Servidor/master que coordina una pool de trabajadores
  """

  # Funciones públicas

  def start(n) do
    pid = spawn(fn -> init(n) end)
    {:ok, pid}
  end

  def run_batch(master, jobs) do
    send(master, {:trabajos, self(), jobs})

    receive do
      results -> results
    end
  end

  def stop(master) do
    send(master, {:stop, self()})

    receive do
      :ok -> :ok
    end
  end

  # Funciones privadas

  defp init(n) do
    workers = for _ <- 1..n, do: Trabajador.start()
    loop(workers)
  end

  defp loop(workers) do
    receive do
      {:trabajos, from, trabajos} ->
        reply = ejecutar_lote(trabajos, workers)
        send(from, reply)
        loop(workers)

      {:stop, from} ->
        Enum.each(workers, fn w -> send(w, :stop) end)
        send(from, :ok)
    end
  end

  defp ejecutar_lote(trabajos, workers) do
    tandas = Enum.chunk_every(trabajos, length(workers))

    tandas
    |> Enum.with_index()
    |> Enum.flat_map(fn {tanda, i} ->
      ejecutar_tanda(tanda, workers, i * length(workers))
    end)
    |> Enum.sort_by(fn {idx, _} -> idx end)
    |> Enum.map(fn {_, res} -> res end)
  end

  defp ejecutar_tanda(trabajos, workers, offset) do
    etiquetados = Enum.with_index(trabajos, offset)
    usados = Enum.take(workers, length(trabajos))

    Enum.zip(etiquetados, usados)
    |> Enum.each(fn {{func, idx}, worker} ->
      send(worker, {:trabajo, self(), fn -> {idx, func.()} end})
    end)

    recolectar(length(trabajos), [])
  end

  defp recolectar(0, acc), do: acc
  defp recolectar(n, acc) do
    receive do
      {:resultado, _pid, {idx, res}} ->
        recolectar(n - 1, [{idx, res} | acc])
    end
  end
end
