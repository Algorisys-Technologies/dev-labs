import Config

config :elixir_ignite,
  port: 4443,
  http_redirect_port: 4080, # Redirects 4080 -> 4443
  hsts: true,               # Enable strict-transport-security
  hsts_max_age: 31_536_000,
  ssl: [
    certfile: "priv/ssl/cert.pem",
    keyfile: "priv/ssl/key.pem"
  ]

config :logger, level: :info
