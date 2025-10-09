defmodule GestorTest do
  use ExUnit.Case
  doctest Gestor

  defmodule GestorRecursosIteracion1.Application do
    @moduledoc false
    use Application

    @impl true
    def start(_type, _args) do
      children =
        if Mix.env() == :test do
          []
        else
          [{Gestor, [:a, :b, :c, :d]}]
        end

      opts = [strategy: :one_for_one, name: GestorRecursosIteracion1.Supervisor]
      Supervisor.start_link(children, opts)
    end

    @impl true
    def stop(_state), do: :ok
  end


  setup do
  # Si ya existe un proceso registrado como :gestor, detenlo antes de iniciar otro
  if Process.whereis(:gestor) do
    GenServer.stop(:gestor)
  end

  {:ok, _pid} = Gestor.start_link([:a, :b, :c, :d])

  on_exit(fn ->
    if Process.whereis(:gestor) do
      GenServer.stop(:gestor)
    end
  end)

  :ok
end



  test "inicia con recursos disponibles" do
    assert Gestor.avail() == 4
  end

  test "asigna un recurso y reduce la disponibilidad" do
    assert {:ok, :a} = Gestor.alloc()
    assert Gestor.avail() == 3
  end

  test "no asigna si no hay recursos disponibles" do
    Gestor.alloc() # :a
    Gestor.alloc() # :b
    Gestor.alloc() # :c
    Gestor.alloc() # :d

    assert Gestor.avail() == 0
    assert Gestor.alloc() == {:error, :sin_recursos}
  end

  test "libera un recurso y aumenta la disponibilidad" do
    {:ok, res} = Gestor.alloc() # Asigna :a
    assert Gestor.avail() == 3

    assert Gestor.release(res) == :ok
    assert Gestor.avail() == 4
  end

  test "no libera un recurso que no fue asignado por el proceso actual" do
  parent = self()

  pid_otro_cliente = spawn_link(fn ->
    {:ok, res_otro} = Gestor.alloc()
    send(parent, {:resource_assigned, res_otro})
    Process.sleep(:infinity)
  end)

  # Esperar el mensaje completo y extraer el recurso
  res_obtenido_por_otro =
    receive do
      {:resource_assigned, res} -> res
    after 5000 ->
      flunk("El proceso spawnado no asignó el recurso a tiempo.")
    end

  assert Gestor.avail() == 3
  assert Gestor.release(res_obtenido_por_otro) == {:error, :recurso_no_reservado}
  assert Gestor.avail() == 3

  Process.exit(pid_otro_cliente, :kill)
end



  test "permite que el mismo proceso reserve múltiples recursos" do
    assert {:ok, r1} = Gestor.alloc()
    assert {:ok, r2} = Gestor.alloc()
    assert Gestor.avail() == 2

    assert Gestor.release(r1) == :ok
    assert Gestor.release(r2) == :ok
    assert Gestor.avail() == 4
  end

  test "maneja la liberación de un recurso no existente o ya liberado" do
    assert Gestor.release(:recurso_inexistente) == {:error, :recurso_no_reservado}

    {:ok, res} = Gestor.alloc()
    Gestor.release(res)
    assert Gestor.release(res) == {:error, :recurso_no_reservado}
  end
end
