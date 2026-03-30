defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :elixir_ignite,
    adapter: Ecto.Adapters.SQLite3
end
