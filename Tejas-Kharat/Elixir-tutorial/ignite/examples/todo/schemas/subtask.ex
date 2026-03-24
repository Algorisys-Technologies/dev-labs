defmodule MyApp.Subtask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subtasks" do
    field :title, :string
    field :status, :string, default: "pending"
    belongs_to :todo_item, MyApp.TodoItem
    timestamps()
  end

  def changeset(sub, attrs) do
    sub
    |> cast(attrs, [:title, :status, :todo_item_id])
    |> validate_required([:title, :todo_item_id])
    |> validate_inclusion(:status, ["pending", "completed"])
  end
end
