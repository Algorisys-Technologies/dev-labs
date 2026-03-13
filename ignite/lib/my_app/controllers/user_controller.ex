defmodule MyApp.UserController do
  import Ignite.Controller

  def show(conn) do
    user_id = conn.params[:id]
    render(conn, "profile", name: "Elixir Enthusiast", id: user_id, email: "N/A")
  end

  def create(conn) do
    username = conn.params["username"] || "anonymous"
    text(conn, "User '#{username}' created successfully!", 201)
  end
end
