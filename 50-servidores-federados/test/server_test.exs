defmodule ServidoresFederados.ServerTest do
  use ExUnit.Case, async: false
  alias ServidoresFederados.{Server, Actor}

  @moduletag :integration


  # Setup para tests locales

  setup do
    {:ok, _pid} = Server.start_link(name: :server_test)

    actors = [
      %Actor{id: "spock@server", full_name: "S'chn T'gai Spock", avatar: "https://example.com/spock.png"},
      %Actor{id: "kirk@server", full_name: "James T. Kirk", avatar: "https://example.com/kirk.png"}
    ]

    :ok = Server.seed(:server_test, actors)
    %{server: :server_test, actors: actors}
  end


  # Tests locales

  test "retrieve_messages devuelve el inbox vacío inicialmente", %{server: server} do
    {:ok, inbox} = Server.retrieve_messages(server, "spock@server")
    assert inbox == []
  end

  test "post_message local entrega mensaje en el inbox", %{server: server} do
    {:ok, _} = Server.post_message(server, "kirk@server", "spock@server", "¡Prepárate para el informe!")
    {:ok, inbox} = Server.retrieve_messages(server, "spock@server")

    assert length(inbox) == 1
    [msg] = inbox
    assert msg.from == "kirk@server"
    assert msg.body == "¡Prepárate para el informe!"
  end

  test "post_message devuelve error si el remitente no existe", %{server: server} do
    assert {:error, :requestor_not_registered} =
             Server.post_message(server, "unknown@server", "spock@server", "Hola")
  end

  test "get_profile obtiene el perfil local", %{server: server} do
    {:ok, profile} = Server.get_profile(server, "spock@server", "kirk@server")
    assert profile.full_name == "James T. Kirk"
    assert profile.id == "kirk@server"
  end

  test "actor no registrado no puede recuperar mensajes", %{server: server} do
    assert {:error, :unknown_actor} = Server.retrieve_messages(server, "unknown@server")
  end

  test "remote_post_message añade al inbox del receptor", %{server: server} do
    {:ok, :delivered} =
      Server.post_message_from_remote(server, "voyager", "spock@server", "Transmisión remota")

    {:ok, inbox} = Server.retrieve_messages(server, "spock@server")
    [msg] = inbox
    assert msg.from == "voyager"
    assert msg.body == "Transmisión remota"
  end

  test "remote_get_profile devuelve error si actor no existe", %{server: server} do
    assert {:error, :unknown_actor} =
             Server.get_profile_from_remote(server, "voyager", "uhura@voyager")
  end


  # Test de federación simulado

  test "simulated federation between two servers in same VM" do
    # Servidor A
    {:ok, server_a} = Server.start_link(name: :server_a)
    :ok = Server.seed(server_a, [%Actor{id: "spock@a", full_name: "Spock", avatar: ""}])

    # Servidor B
    {:ok, server_b} = Server.start_link(name: :server_b)
    :ok = Server.seed(server_b, [%Actor{id: "uhura@b", full_name: "Uhura", avatar: ""}])

    # Consultar perfil remoto simulando RPC
    {:ok, profile} =
      Server.get_profile_from_remote(server_b, "spock@a", "uhura@b")

    assert profile.full_name == "Uhura"

    # Enviar mensaje remoto simulando RPC
    {:ok, :delivered} =
      Server.post_message_from_remote(server_b, "spock@a", "uhura@b", "Mensaje de prueba")

    # Comprobar inbox en servidor B
    {:ok, inbox} = Server.retrieve_messages(server_b, "uhura@b")
    assert length(inbox) == 1
    [msg] = inbox
    assert msg.from == "spock@a"
    assert msg.body == "Mensaje de prueba"
  end
end
