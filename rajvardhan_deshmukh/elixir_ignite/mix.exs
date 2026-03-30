defmodule Ignite.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_ignite,
      version: "0.1.27",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib", "examples"],
      deps: deps(),
      releases: [
        ignite: [
          include_executables_for: [:unix, :windows],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :ssl, :public_key],
      mod: {Ignite.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.17"}
    ]
  end
end
