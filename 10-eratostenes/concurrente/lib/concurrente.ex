defmodule Filtro do
  def start(primo, siguiente_pid, sink_pid) do
    spawn(__MODULE__, :loop, [primo, siguiente_pid, sink_pid])
  end

  def loop(primo, siguiente_pid, sink_pid) do
    receive do
      # Si el número es divisible por mi primo, lo descarto y continúo
      {:numero, n} when rem(n, primo) == 0 ->
        loop(primo, siguiente_pid, sink_pid)

      # Si soy el último filtro (apunto al Sink), 'n' es un nuevo primo
      {:numero, n} when siguiente_pid == sink_pid ->
        send(sink_pid, {:nuevo_primo, n, self()})
        receive do
          {:actualizado, nuevo_siguiente_pid} ->
            loop(primo, nuevo_siguiente_pid, sink_pid)
        end

      # Si no es divisible, simplemente paso el número al siguiente filtro de la cadena
      {:numero, n} ->
        send(siguiente_pid, {:numero, n})
        loop(primo, siguiente_pid, sink_pid)

      # Al recibir la señal de fin, la propago por la cadena
      :fin ->
        send(siguiente_pid, :fin)
    end
  end
end

defmodule Sink do
  def start(pid_principal) do
    spawn(__MODULE__, :loop, [pid_principal, [2]])
  end

  def loop(pid_principal, primos_acumulados) do
    receive do
      {:nuevo_primo, n, ultimo_filtro_pid} ->
        # Creo el nuevo filtro, que apuntará al Sink
        nuevo_filtro_pid = Filtro.start(n, self(), self())
        # Le respondo al filtro anterior para que actualice su 'siguiente_pid'
        send(ultimo_filtro_pid, {:actualizado, nuevo_filtro_pid})
        # Acumulo el nuevo primo y continúo.
        loop(pid_principal, [n | primos_acumulados])

      # La señal de fin ha llegado al final de la cadena
      :fin ->
        # Invierto la lista para ordenarla y la envío al proceso principal
        primos_ordenados = Enum.reverse(primos_acumulados)
        send(pid_principal, {:primos_encontrados, primos_ordenados})
    end
  end
end

defmodule EratostenesPipe do
  def primos(n) when n < 2, do: []
  def primos(2), do: [2]

  def primos(n) do
    pid_principal = self()
    # Creo el Sink
    sink_pid = Sink.start(pid_principal)
    # Creo el filtro para el primo 2
    primer_filtro_pid = Filtro.start(2, sink_pid, sink_pid)

    # Envío todos los números candidatos al principio de la cadena de filtros
    for num <- 3..n do
      send(primer_filtro_pid, {:numero, num})
    end

    # Envío la señal de finalización para que la cadena se cierre y devuelva el resultado
    send(primer_filtro_pid, :fin)

    # Espero a que el Sink me envíe la lista final de primos encontrados
    receive do
      {:primos_encontrados, primos} -> primos
    end
  end
end
