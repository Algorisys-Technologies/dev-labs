ExUnit.start()

# Automatically run migrations for the test database
Ecto.Migrator.run(MyApp.Repo, :up, all: true, log: false)
