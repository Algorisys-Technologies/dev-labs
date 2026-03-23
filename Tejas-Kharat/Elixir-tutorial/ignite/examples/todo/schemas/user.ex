defmodule MyApp.TodoUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: pass}} = cs) do
    put_change(cs, :password_hash, :crypto.hash(:sha256, pass) |> Base.encode16())
  end

  defp put_pass_hash(cs), do: cs
end
