🔥 Ignite

TODO: Add a short project description here (what Ignite does and why it exists)

📦 Installation & Setup

Follow these steps to set up the project locally:

# Fetch dependencies
mix deps.get

# Compile the project
mix compile

# Create the database
mix ecto.create

# Run migrations (create tables)
mix ecto.migrate

# Seed initial data (e.g., categories)
mix run priv/repo/seeds.exs
➕ Adding Ignite as a Dependency

If the package is published on Hex, you can install it by adding ignite to your dependencies in mix.exs:

def deps do
  [
    {:ignite, "~> 0.1.0"}
  ]
end

Then run:

mix deps.get
📚 Documentation

Documentation can be generated using ExDoc and published to HexDocs.

Once available, you can access it here:
👉 https://hexdocs.pm/ignite

🛠 Notes
deps/ is recreated after running mix deps.get
_build/ is generated during compilation
Database is created using mix ecto.create
Tables are created via migrations
Seed script populates initial data (like categories)
