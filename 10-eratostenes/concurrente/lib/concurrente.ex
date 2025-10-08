defmodule Filtro do
  def start(primo, siguiente_pid, original_sink_pid) do
    spawn(__MODULE__, :loop, [primo, siguiente_pid, original_sink_pid])
  end

  def loop(primo, siguiente_pid, original_sink_pid) do
    receive do
      {:numero, n} ->
        if rem(n, primo) == 0 do
          loop(primo, siguiente_pid, original_sink_pid)
        else
          # Si no es divisible
          if siguiente_pid == original_sink_pid do
            # 'n' es un nuevo primo.
            
            # Notificar al Sink que 'n' es un primo para que lo acumule.
            send(original_sink_pid, {:numero, n}) 
            
            # Crear un nuevo filtro para 'n' y engancharlo a la cadena.
            nuevo_filtro_pid = Filtro.start(n, original_sink_pid, original_sink_pid)
            
            # Actualizar su 'siguiente_pid' para apuntar al nuevo filtro.
            loop(primo, nuevo_filtro_pid, original_sink_pid)
          else
            # Si el siguiente es otro filtro, simplemente le enviamos el número
            send(siguiente_pid, {:numero, n})
            loop(primo, siguiente_pid, original_sink_pid)
          end
        end

      {:get_primos, sender_pid} ->
        send(siguiente_pid, {:get_primos, sender_pid})
        receive do
          {:primos_recopilados, tail_primos} ->
            send(sender_pid, {:primos_recopilados, [primo | tail_primos]})
        end
        loop(primo, siguiente_pid, original_sink_pid)

      :fin ->
        send(siguiente_pid, :fin)
    end
  end
end

defmodule Sink do
  def start(pid_principal) do
    spawn(__MODULE__, :loop, [pid_principal, []])
  end

  def loop(pid_principal, primos_acumulados) do
    receive do
      {:numero, n} ->
        # El Sink acumula los números primos que le llegan.
        loop(pid_principal, primos_acumulados ++ [n])

      {:get_primos, sender_pid} ->
        send(sender_pid, {:primos_recopilados, primos_acumulados})
        loop(pid_principal, primos_acumulados)

      :fin ->
        send(pid_principal, {:primos_encontrados, primos_acumulados})
    end
  end
end

defmodule EratostenesPipe do
  @moduledoc """
  Criba de Eratostenes usando procesos encadenados (pipe de filtros).
  """

  def primos(n) when n < 2, do: []
  def primos(2), do: [2] # <-- Añadir una función de guarda específica para n=2
  def primos(n) do
    pid_principal = self()
    sink_pid = Sink.start(pid_principal)

    primer_filtro_pid = Filtro.start(2, sink_pid, sink_pid)
    send(sink_pid, {:numero, 2}) # El primo 2 se envía al Sink porque es el primer primo.

    Enum.each(3..n, fn x -> # Envía cada número secuencialmente al `primer_filtro_pid`
      send(primer_filtro_pid, {:numero, x})
    end)

    send(primer_filtro_pid, :fin)

    receive do
      {:primos_encontrados, primos} -> primos
    end
  end
end