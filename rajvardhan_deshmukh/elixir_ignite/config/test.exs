import Config

# Test port (different from dev's 4000)
config :elixir_ignite, port: 4002

# Use a separate test database
config :elixir_ignite, MyApp.Repo, database: "ignite_test.db"

# Reduce logging noise during tests
config :logger, level: :warning
