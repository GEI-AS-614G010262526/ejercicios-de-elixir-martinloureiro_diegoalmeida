defmodule Gestor do
  use GenServer

  ## Funciones API para el cliente

  @doc """
  Inicia el servidor Gestor y lo registra con el nombre `gestor`.
  Requiere una lista inicial de recursos.
  """
  def start_link(initial_resources) when is_list(initial_resources) do
    GenServer.start_link(__MODULE__, initial_resources, name: :gestor)
  end

  @doc """
  Solicita un recurso al Gestor.
  Devuelve `{:ok, recurso}` si se asigna un recurso,
  o `{:error, :sin_recursos}` si no hay recursos disponibles.
  """
  def alloc do
    GenServer.call(:gestor, {:alloc, self()})
  end

  @doc """
  Libera un recurso previamente asignado al cliente.
  Devuelve `:ok` si el recurso se libera correctamente,
  o `{:error, :recurso_no_reservado}` si el recurso no fue asignado a este proceso.
  """
  def release(resource) do
    GenServer.call(:gestor, {:release, self(), resource})
  end

  @doc """
  Devuelve el número de recursos disponibles en el Gestor.
  """
  def avail do
    GenServer.call(:gestor, :avail)
  end

  ## Callbacks del GenServer

  @impl true
  def init(initial_resources) do
    # El estado del gestor:
    # `available`: Una lista de recursos que están libres.
    # `assigned`: Un mapa que asocia cada recurso asignado con el PID del proceso que lo tiene.
    {:ok, %{available: initial_resources, assigned: %{}}}
  end

  @impl true
  def handle_call({:alloc, from}, _from, %{available: [], assigned: assigned} = state) do
    # No hay recursos disponibles
    {:reply, {:error, :sin_recursos}, state}
  end

  @impl true
  def handle_call({:alloc, from}, _from, %{available: [resource | rest], assigned: assigned} = state) do
    # Asigna el primer recurso disponible
    new_assigned = Map.put(assigned, resource, from)
    new_state = %{available: rest, assigned: new_assigned}
    {:reply, {:ok, resource}, new_state}
  end

  @impl true
  def handle_call({:release, from, resource}, _from, %{available: available, assigned: assigned} = state) do
    case Map.get(assigned, resource) do
      ^from ->
        # El recurso fue asignado a este PID, liberarlo
        new_assigned = Map.delete(assigned, resource)
        new_available = [resource | available]
        new_state = %{available: new_available, assigned: new_assigned}
        {:reply, :ok, new_state}
      _ ->
        # El recurso no fue asignado a este PID o no existe
        {:reply, {:error, :recurso_no_reservado}, state}
    end
  end

  @impl true
  def handle_call(:avail, _from, %{available: available} = state) do
    {:reply, length(available), state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end