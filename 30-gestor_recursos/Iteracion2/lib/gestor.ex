defmodule Gestor do
  use GenServer

  ## =====================
  ## API del cliente
  ## =====================

  @doc """
  Inicia el servidor Gestor y lo registra globalmente con el nombre `:gestor`.
  Requiere una lista inicial de recursos.
  """
  def start_link(initial_resources) when is_list(initial_resources) do
    GenServer.start_link(__MODULE__, initial_resources, name: {:global, :gestor})
  end

  @doc """
  Solicita un recurso al Gestor.
  Devuelve `{:ok, recurso}` si se asigna un recurso,
  o `{:error, :sin_recursos}` si no hay recursos disponibles.
  """
  def alloc do
    GenServer.call({:global, :gestor}, {:alloc, self()})
  end

  @doc """
  Libera un recurso previamente asignado al cliente.
  Devuelve `:ok` si el recurso se libera correctamente,
  o `{:error, :recurso_no_reservado}` si el recurso no fue asignado a este proceso.
  """
  def release(resource) do
    GenServer.call({:global, :gestor}, {:release, self(), resource})
  end

  @doc """
  Devuelve el número de recursos disponibles en el Gestor.
  """
  def avail do
    GenServer.call({:global, :gestor}, :avail)
  end

  ## =====================
  ## Callbacks del GenServer
  ## =====================

  @impl true
  def init(initial_resources) do
    {:ok, %{available: initial_resources, assigned: %{}}}
  end

  @impl true
  def handle_call({:alloc, from}, _from, %{available: [], assigned: assigned} = state) do
    {:reply, {:error, :sin_recursos}, state}
  end

  @impl true
  def handle_call({:alloc, from}, _from, %{available: [resource | rest], assigned: assigned} = state) do
    new_assigned = Map.put(assigned, resource, from)
    new_state = %{available: rest, assigned: new_assigned}
    {:reply, {:ok, resource}, new_state}
  end

  @impl true
  def handle_call({:release, from, resource}, _from, %{available: available, assigned: assigned} = state) do
    case Map.get(assigned, resource) do
      ^from ->
        new_assigned = Map.delete(assigned, resource)
        new_available = [resource | available]
        {:reply, :ok, %{available: new_available, assigned: new_assigned}}

      _ ->
        {:reply, {:error, :recurso_no_reservado}, state}
    end
  end

  @impl true
  def handle_call(:avail, _from, %{available: available} = state) do
    {:reply, length(available), state}
  end

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}
  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
