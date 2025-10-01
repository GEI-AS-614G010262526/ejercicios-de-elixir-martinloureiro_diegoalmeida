defmodule EratostenesConcurrente do
  @moduledoc """
  Devuelve la lista de primos entre 2 y n usando concurrencia por bloques.
  """

  defp generar_lista(n), do: Enum.to_list(2..n)

  defp cribar([]), do: []
  defp cribar([p | resto]) do
    bloques = Enum.chunk_every(resto, 10_000)
    filtrados =
      bloques
      |> Task.async_stream(
        fn bloque -> Enum.filter(bloque, fn x -> rem(x, p) != 0 end) end,
        max_concurrency: System.schedulers_online()
      )
      |> Enum.flat_map(fn {:ok, lista} -> lista end)

    [p | cribar(filtrados)]
  end

  def primos(n) when is_integer(n) and n < 2, do: []
  def primos(n) when is_integer(n) do
    n
    |> generar_lista()
    |> cribar()
  end
end