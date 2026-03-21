defmodule Ignite.MixProject do
  use Mix.Project

  def project do
    [
      app: :ignite,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        ignite: [
          include_executables_for: [:unix],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :ssl, :public_key],
      mod: {Ignite.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.17"}
    ]
  end
end
