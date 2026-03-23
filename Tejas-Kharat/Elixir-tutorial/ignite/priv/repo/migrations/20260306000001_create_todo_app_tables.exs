defmodule MyApp.Repo.Migrations.CreateTodoAppTables do
  use Ecto.Migration

  def change do
    create table(:todo_users) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      timestamps()
    end

    create unique_index(:todo_users, [:email])

    create table(:categories) do
      add :name, :string, null: false
      add :color, :string
      timestamps()
    end

    create table(:todo_items) do
      add :title, :string, null: false
      add :description, :text
      add :priority, :string, default: "medium"
      add :status, :string, default: "pending"
      add :due_date, :date
      add :user_id, references(:todo_users, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :nilify_all)
      timestamps()
    end

    create index(:todo_items, [:user_id])
    create index(:todo_items, [:category_id])

    create table(:subtasks) do
      add :title, :string, null: false
      add :completed, :boolean, default: false
      add :todo_item_id, references(:todo_items, on_delete: :delete_all)
      timestamps()
    end

    create index(:subtasks, [:todo_item_id])
  end
end
