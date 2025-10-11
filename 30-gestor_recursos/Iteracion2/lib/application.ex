defmodule GestorRecursosIteracion2.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Gestor, [:a, :b, :c, :d]}
    ]

    opts = [strategy: :one_for_one, name: GestorRecursosIteracion2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
