defmodule MyApp.TodoUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_required([:username, :email, :password])
    |> validate_length(:password, min: 6)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  def verify_password(user, password) do
    :crypto.hash(:sha256, password) |> Base.encode16() == user.password_hash
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: pass}} = cs) do
    put_change(cs, :password_hash, :crypto.hash(:sha256, pass) |> Base.encode16())
  end

  defp put_pass_hash(cs), do: cs
end
