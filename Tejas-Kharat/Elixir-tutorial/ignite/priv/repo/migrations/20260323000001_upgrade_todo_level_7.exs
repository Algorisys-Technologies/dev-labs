defmodule MyApp.Repo.Migrations.UpgradeTodoLevel7 do
  use Ecto.Migration

  def change do
    execute(fn ->
      # todo_users
      {:ok, %{rows: rows}} = repo().query("PRAGMA table_info(todo_users)")
      cols = Enum.map(rows, fn [_, name | _] -> name end)
      unless "username" in cols, do: repo().query!("ALTER TABLE todo_users ADD COLUMN username TEXT")

      # todo_items
      {:ok, %{rows: rows}} = repo().query("PRAGMA table_info(todo_items)")
      cols = Enum.map(rows, fn [_, name | _] -> name end)
      unless "bookmarked" in cols, do: repo().query!("ALTER TABLE todo_items ADD COLUMN bookmarked BOOLEAN NOT NULL DEFAULT 0")

      # subtasks
      {:ok, %{rows: rows}} = repo().query("PRAGMA table_info(subtasks)")
      cols = Enum.map(rows, fn [_, name | _] -> name end)
      unless "status" in cols, do: repo().query!("ALTER TABLE subtasks ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'")

      # categories
      {:ok, %{rows: rows}} = repo().query("PRAGMA table_info(categories)")
      cols = Enum.map(rows, fn [_, name | _] -> name end)
      unless "user_id" in cols, do: repo().query!("ALTER TABLE categories ADD COLUMN user_id INTEGER REFERENCES todo_users(id) ON DELETE CASCADE")
    end)
  end
end
