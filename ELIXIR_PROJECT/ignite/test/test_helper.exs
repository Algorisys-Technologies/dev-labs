ExUnit.start()
Ecto.Migrator.run(MyApp.Repo, :up, all: true, log: false)
