defmodule MyApp.Repo.Migrations.AddTodoUserFields do
  use Ecto.Migration

  def up do
    # users: email already exists, add password_hash only
    execute "ALTER TABLE users ADD COLUMN password_hash TEXT"

    # todo_items: add completed and user_id
    execute "ALTER TABLE todo_items ADD COLUMN completed INTEGER DEFAULT 0"
    execute "ALTER TABLE todo_items ADD COLUMN user_id INTEGER REFERENCES users(id)"
  end

  def down do
    :ok
  end
end
