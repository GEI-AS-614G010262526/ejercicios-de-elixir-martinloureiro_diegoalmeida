defmodule ServidoresFederados.Server do
  @moduledoc """
  Servidor federado.
  """

  use GenServer
  alias ServidoresFederados.Actor

  ## Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def seed(server \\ __MODULE__, actors) when is_list(actors) do
    GenServer.call(server, {:seed, actors})
  end

  def get_profile(server \\ __MODULE__, requestor, actor_id) do
    GenServer.call(server, {:get_profile, requestor, actor_id})
  end

  def post_message(server \\ __MODULE__, sender, receiver, message) do
    GenServer.call(server, {:post_message, sender, receiver, message})
  end

  def retrieve_messages(server \\ __MODULE__, actor_id) do
    GenServer.call(server, {:retrieve_messages, actor_id})
  end

  ## API remota (RPC)

  def get_profile_from_remote(server \\ __MODULE__, from_server, actor_id) do
    GenServer.call(server, {:remote_get_profile, from_server, actor_id})
  end

  def post_message_from_remote(server \\ __MODULE__, from_server, receiver, message) do
    GenServer.call(server, {:remote_post_message, from_server, receiver, message})
  end

  ## GenServer callbacks

  def init(:ok) do
    {:ok, %{node: Node.self(), actors: %{}}}
  end

  def handle_call({:seed, actors}, _from, state) do
    actors_map =
      Enum.reduce(actors, %{}, fn %Actor{id: id} = a, acc ->
        Map.put(acc, id, a)
      end)

    {:reply, :ok, %{state | actors: actors_map}}
  end

  def handle_call({:retrieve_messages, actor_id}, _from, state) do
    case Map.fetch(state.actors, actor_id) do
      {:ok, %Actor{inbox: inbox} = actor} ->
        updated_actor = %{actor | inbox: []}
        new_state = put_in(state.actors[actor_id], updated_actor)
        {:reply, {:ok, inbox}, new_state}

      :error ->
        {:reply, {:error, :unknown_actor}, state}
    end
  end

  def handle_call({:get_profile, requestor, actor_id}, _from, state) do
    if actor_registered_on_requester?(requestor, state) do
      case Map.fetch(state.actors, actor_id) do
        {:ok, %Actor{} = actor} ->
          profile = Map.take(actor, [:id, :full_name, :avatar])
          {:reply, {:ok, profile}, state}

        :error ->
          case actor_to_node(actor_id) do
            nil -> {:reply, {:error, :bad_actor_id}, state}
            target_node ->
              rpc_res =
                :rpc.call(
                  target_node,
                  __MODULE__,
                  :get_profile_from_remote,
                  [node_name_string(), actor_id]
                )

              {:reply, rpc_res, state}
          end
      end
    else
      {:reply, {:error, :requestor_not_registered}, state}
    end
  end

  def handle_call({:post_message, sender, receiver, message}, _from, state) do
    if actor_registered_on_requester?(sender, state) do
      case Map.fetch(state.actors, receiver) do
        {:ok, %Actor{} = actor} ->
          updated =
            %{actor | inbox: actor.inbox ++ [%{from: sender, body: message, at: DateTime.utc_now()}]}

          new_state = put_in(state.actors[receiver], updated)
          {:reply, {:ok, :delivered_local}, new_state}

        :error ->
          case actor_to_node(receiver) do
            nil -> {:reply, {:error, :bad_actor_id}, state}
            target_node ->
              rpc_res =
                :rpc.call(
                  target_node,
                  __MODULE__,
                  :post_message_from_remote,
                  [node_name_string(), receiver, message]
                )

              {:reply, rpc_res, state}
          end
      end
    else
      {:reply, {:error, :requestor_not_registered}, state}
    end
  end

  ## Callbacks remotas

  def handle_call({:remote_get_profile, _from_server, actor_id}, _from, state) do
    case Map.fetch(state.actors, actor_id) do
      {:ok, %Actor{} = actor} ->
        profile = Map.take(actor, [:id, :full_name, :avatar])
        {:reply, {:ok, profile}, state}

      :error ->
        {:reply, {:error, :unknown_actor}, state}
    end
  end

  def handle_call({:remote_post_message, from_server, receiver, message}, _from, state) do
    case Map.fetch(state.actors, receiver) do
      {:ok, %Actor{} = actor} ->
        updated =
          %{actor | inbox: actor.inbox ++ [%{from: from_server, body: message, at: DateTime.utc_now()}]}

        new_state = put_in(state.actors[receiver], updated)
        {:reply, {:ok, :delivered}, new_state}

      :error ->
        {:reply, {:error, :unknown_actor}, state}
    end
  end

  ## Helpers

  # Comprueba si el actor está registrado localmente
  defp actor_registered_on_requester?(actor_id, state) do
    Map.has_key?(state.actors, actor_id)
  end

  # Nodo actual como string
  defp node_name_string do
    Atom.to_string(Node.self())
  end

  # Mapea actor_id -> nodo automáticamente
  defp actor_to_node(actor_id) do
    case String.split(actor_id, "@") do
      [_, server] -> String.to_atom("#{server}@127.0.0.1")
      _ -> nil
    end
  end
end
