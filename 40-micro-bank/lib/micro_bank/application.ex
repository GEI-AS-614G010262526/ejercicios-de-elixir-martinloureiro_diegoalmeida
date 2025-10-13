defmodule MicroBank.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {MicroBank, name: MicroBank}
    ]

    opts = [strategy: :one_for_one, name: MicroBank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

