defmodule MyApp.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :color, :string
    has_many :todo_items, MyApp.TodoItem
    timestamps()
  end

  def changeset(cat, attrs) do
    cat
    |> cast(attrs, [:name, :color])
    |> validate_required([:name])
  end
end
