defmodule MyApp.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :color, :string, default: "#3498db"
    has_many :todo_items, MyApp.TodoItem
    timestamps()
  end

  def changeset(category, attrs) do
    category |> cast(attrs, [:name, :color]) |> validate_required([:name])
  end
end
