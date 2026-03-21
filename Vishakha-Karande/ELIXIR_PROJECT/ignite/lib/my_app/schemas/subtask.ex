defmodule MyApp.Subtask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subtasks" do
    field :title, :string
    field :completed, :boolean, default: false

    belongs_to :todo_item, MyApp.TodoItem

    timestamps()
  end

  def changeset(subtask, attrs) do
    subtask
    |> cast(attrs, [:title, :completed, :todo_item_id])
    |> validate_required([:title])
  end
end
