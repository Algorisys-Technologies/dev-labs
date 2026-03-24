defmodule MyApp.SessionController do
  import Ignite.Controller
  alias MyApp.{Repo, TodoUser}

  def login(conn) do
    email = conn.params["email"] || ""
    password = conn.params["password"] || ""

    case Repo.get_by(TodoUser, email: email) do
      nil ->
        conn
        |> put_flash(:error, "No account with this email")
        |> redirect(to: "/todo")

      user ->
        if TodoUser.verify_password(user, password) do
          new_session = Map.put(conn.session, "user_id", user.id)
          
          # Replace session map in the conn
          conn = %Ignite.Conn{conn | session: new_session}
          
          conn
          |> redirect(to: "/todo")
        else
          conn
          |> put_flash(:error, "Invalid password")
          |> redirect(to: "/todo")
        end
    end
  end

  def register(conn) do
    attrs = %{
      username: conn.params["username"] || "",
      email: conn.params["email"] || "",
      password: conn.params["password"] || ""
    }

    changeset = TodoUser.registration_changeset(%TodoUser{}, attrs)

    case Repo.insert(changeset) do
      {:ok, user} ->
        new_session = Map.put(conn.session, "user_id", user.id)
        
        %Ignite.Conn{conn | session: new_session}
        |> redirect(to: "/todo")

      {:error, changeset} ->
        errors = format_errors(changeset)

        conn
        |> put_flash(:error, "Registration failed: #{errors}")
        |> redirect(to: "/todo")
    end
  end

  def logout(conn) do
    # Clear the entire session or just the user_id
    new_session = Map.delete(conn.session, "user_id")

    %Ignite.Conn{conn | session: new_session}
    |> redirect(to: "/todo")
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {field, msgs} ->
      "#{field} #{Enum.join(msgs, ", ")}"
    end)
  end
end
