defmodule MyApp.UserController do
  import Ignite.Controller

  def show(conn) do
    user_id = conn.params[:id]
    text(conn, "Showing profile for User ##{user_id}")
  end
end
