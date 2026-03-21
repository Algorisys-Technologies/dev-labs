import Config

# For production, we typically read from environment variables in runtime.exs.
# This file contains static production configuration.

config :ignite,
  hsts: true,
  hsts_max_age: 31_536_000

# Database pool size for production
config :ignite, MyApp.Repo,
  pool_size: 10

# Do not print debug messages in production
config :logger, level: :info
