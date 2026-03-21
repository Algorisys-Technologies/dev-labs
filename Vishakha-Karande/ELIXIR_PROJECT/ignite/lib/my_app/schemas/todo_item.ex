defmodule MyApp.TodoItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_items" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :priority, :string, default: "medium"
    field :completed, :boolean, default: false
    field :due_date, :date

    belongs_to :user, MyApp.User
    belongs_to :category, MyApp.Category
    has_many :subtasks, MyApp.Subtask

    timestamps()
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :status, :priority, :completed, :due_date, :user_id, :category_id])
    |> validate_required([:title])
    |> validate_inclusion(:status, ["pending", "in_progress", "done"])
    |> validate_inclusion(:priority, ["low", "medium", "high"])
  end
end
