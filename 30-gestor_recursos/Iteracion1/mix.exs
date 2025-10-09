defmodule GestorRecursosIteracion1.Mix do
  use Mix.Project

  def project do
    [
      app: :Iteracion1,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  def application do
    [
      mod: {GestorRecursosIteracion1.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end