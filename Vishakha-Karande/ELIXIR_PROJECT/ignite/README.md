# Ignite

**TODO: Add description**

## Installation
mix deps.get       # recreates deps/
mix compile         # recreates _build/
mix ecto.create     # recreates the .db
mix ecto.migrate    # creates tables
mix run priv/repo/seeds.exs  # adds categories

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ignite` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ignite, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ignite>.

