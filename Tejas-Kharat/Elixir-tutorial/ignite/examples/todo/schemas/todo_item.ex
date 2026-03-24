defmodule MyApp.TodoItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_items" do
    field :title, :string
    field :description, :string
    field :priority, :string, default: "medium"
    field :status, :string, default: "pending"
    field :bookmarked, :boolean, default: false
    field :due_date, :date
    belongs_to :user, MyApp.TodoUser
    belongs_to :category, MyApp.Category
    has_many :subtasks, MyApp.Subtask
    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:title, :description, :priority, :status, :bookmarked, :due_date, :user_id, :category_id])
    |> validate_required([:title, :user_id])
    |> validate_inclusion(:priority, ["low", "medium", "high"])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "archived"])
    |> foreign_key_constraint(:category_id)
    |> foreign_key_constraint(:user_id)
  end
end
