defmodule ServidoresFederados.Application do
  @moduledoc false
use Application


def start(_type, _args) do
children = [
# No arranca automáticamente un servidor: dejamos que el desarrollador lo haga
# con ServidoresFederados.Server.start_link/0 (para facilitar pruebas multNodo).
]


opts = [strategy: :one_for_one, name: ServidoresFederados.Supervisor]
Supervisor.start_link(children, opts)
end
end
