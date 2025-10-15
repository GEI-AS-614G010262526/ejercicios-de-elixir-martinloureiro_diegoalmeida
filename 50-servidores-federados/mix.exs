defmodule ServidoresFederados.MixProject do
use Mix.Project


def project do
[
app: :servidores_federados,
version: "0.1.0",
elixir: "~> 1.14",
start_permanent: Mix.env() == :prod,
deps: []
]
end


def application do
[
extra_applications: [:logger],
mod: {ServidoresFederados.Application, []}
]
end

end
