import Config

config :ignite, port: 4002

config :ignite, MyApp.Repo,
  database: "ignite_test.db",
  pool_size: 5

# Reduce log noise during tests
config :logger, level: :warning
