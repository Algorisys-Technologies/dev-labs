import Config

# lib/my_app/config/prod.exs
# In production, we run on standard HTTPS port (mapped to 4443 here for testing)
# and redirect all HTTP traffic to HTTPS.
config :ignite,
  port: 4443,
  http_redirect_port: 4080,
  # HSTS tells browsers to ONLY use HTTPS for this site
  hsts: true,
  hsts_max_age: 31_536_000,
  # Point to your production certificates
  ssl: [
    certfile: "priv/ssl/cert.pem",
    keyfile: "priv/ssl/key.pem"
  ]

config :ignite, MyApp.Repo,
  database: "ignite_prod.db",
  pool_size: 10

config :logger, level: :info
