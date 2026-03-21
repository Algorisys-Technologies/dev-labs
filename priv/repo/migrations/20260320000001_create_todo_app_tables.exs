defmodule MyApp.Repo.Migrations.CreateTodoAppTables do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :color, :string, default: "#3498db"
      timestamps()
    end

    create table(:todo_items) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, default: "pending"
      add :priority, :string, default: "medium"
      add :completed, :boolean, default: false
      add :due_date, :date
      add :user_id, references(:users, on_delete: :nilify_all)
      add :category_id, references(:categories, on_delete: :nilify_all)
      timestamps()
    end

    create table(:subtasks) do
      add :title, :string, null: false
      add :completed, :boolean, default: false
      add :todo_item_id, references(:todo_items, on_delete: :delete_all)
      timestamps()
    end
  end
end
