defmodule GestorRecursosIteracion1.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Mix.env() do
        :test -> []
        _ -> [{Gestor, [:a, :b, :c, :d]}]
      end

    opts = [strategy: :one_for_one, name: GestorRecursosIteracion1.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
