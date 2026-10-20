defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MyApp.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.0"},
      {:ecto_sql, "~> 3.14"},
      {:ecto_sqlite3, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate"]
    ]
  end
end
