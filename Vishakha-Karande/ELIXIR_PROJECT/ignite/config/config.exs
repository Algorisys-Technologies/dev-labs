import Config

config :ignite, 
  env: config_env(),
  port: 4000,
  rate_limit: [
    max_requests: 100,
    window_ms: 60_000
  ]

config :ignite, MyApp.Repo,
  database: "ignite_dev.db",
  pool_size: 5

config :ignite,
  ecto_repos: [MyApp.Repo]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
