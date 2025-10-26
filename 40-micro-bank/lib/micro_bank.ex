defmodule MicroBank do
  use GenServer

  #Funciones públicas

  def deposit(who, amount) do
    deposit(__MODULE__, who, amount)
  end

  def ask(who) do
    ask(__MODULE__, who)
  end

  def withdraw(who, amount) do
    withdraw(__MODULE__, who, amount)
  end

  def stop() do
    stop(__MODULE__)
  end

  #Funciones públicas largas

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def deposit(server, who, amount) do
    GenServer.call(server, {:deposit, who, amount})
  end

  def ask(server, who) do
    GenServer.call(server, {:ask, who})
  end

  def withdraw(server, who, amount) do
    GenServer.call(server, {:withdraw, who, amount})
  end

  def stop(server) do
    GenServer.stop(server)
  end

  #Funciones privadas

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:deposit, who, amount}, _from, state) do
    new_balance = Map.get(state, who, 0) + amount
    new_state = Map.put(state, who, new_balance)
    {:reply, {:ok, new_balance}, new_state}
  end

  @impl true
  def handle_call({:ask, who}, _from, state) do
    balance = Map.get(state, who, 0)
    {:reply, {:ok, balance}, state}
  end

  @impl true
  def handle_call({:withdraw, who, amount}, _from, state) do
    current_balance = Map.get(state, who, 0)

    if current_balance < amount do
      {:reply, {:error, :insufficient_funds}, state}
    else
      new_balance = current_balance - amount
      new_state = Map.put(state, who, new_balance)
      {:reply, {:ok, new_balance}, new_state}
    end
  end
end
