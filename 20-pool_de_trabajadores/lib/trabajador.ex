defmodule Trabajador do
  @moduledoc"""
  El trabajador recibe trabajos y devuelve resultados.
  """

  def start() do
    spawn(fn -> loop() end)
  end

  defp loop() do
    receive do
      {:trabajo, from, func} when is_function(func, 0) ->
        result = func.()
        send(from, {:resultado, self(), result})
        loop()

      :stop ->
        :ok
    end
  end
end
