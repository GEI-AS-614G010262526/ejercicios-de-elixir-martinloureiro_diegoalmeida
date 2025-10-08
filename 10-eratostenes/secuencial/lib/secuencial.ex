defmodule Eratostenes do
  @moduledoc """
    Devuelve la lista de primos entre 2 y n.
  """

  defp generar_lista(n), do: Enum.to_list(2..n)

  defp cribar([]), do: []
  defp cribar([p | resto]) do
    [p | cribar(Enum.filter(resto, fn x -> rem(x, p) != 0 end))]
  end

  def primos(n) when n < 2, do: []
  def primos(n) do
    n
    |> generar_lista()
    |> cribar()
  end
end
