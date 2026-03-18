import Config

config :ignite, MyApp.Repo,
  database: "ignite_dev.db",
  pool_size: 5

config :ignite,
  ecto_repos: [MyApp.Repo]
