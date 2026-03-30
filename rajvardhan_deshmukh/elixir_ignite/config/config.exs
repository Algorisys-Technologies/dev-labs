import Config

config :elixir_ignite, MyApp.Repo,
  database: "ignite_dev.db",
  pool_size: 5

# We have `elixir_ignite` as the app
config :elixir_ignite,
  env: :dev,
  ecto_repos: [MyApp.Repo]

# Structured logging with Request ID
config :elixir_ignite,
  env: config_env(),
  port: 4000,
  app_name: "Ignite",
  rate_limit: [
    max_requests: 100,   # per window
    window_ms: 60_000    # 1 minute
  ]

# Import environment-specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
