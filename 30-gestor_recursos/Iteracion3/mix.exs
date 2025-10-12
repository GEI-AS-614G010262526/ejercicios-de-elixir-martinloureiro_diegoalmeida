defmodule GestorRecursosIteracion3.Mix do
  use Mix.Project

  def project do
    [
      app: :Iteracion2,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {GestorRecursosIteracion3.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
