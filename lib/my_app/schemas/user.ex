defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string

    has_many :todos, MyApp.TodoItem

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password_hash])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc "Simple password hashing using :crypto (no bcrypt dependency needed)"
  def hash_password(password) when is_binary(password) do
    :crypto.hash(:sha256, password) |> Base.encode16()
  end
end
