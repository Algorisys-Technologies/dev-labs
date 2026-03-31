defmodule MyApp.AuthController do
  import Ignite.Controller
  alias MyApp.{Repo, User}

  def login_form(conn) do
    error = conn.params["error"] || ""
    html(conn, render_page(conn, "Sign In", "/login", "Don't have an account? <a href='/signup'>Sign up</a>", error))
  end

  def signup_form(conn) do
    error = conn.params["error"] || ""
    html(conn, render_page(conn, "Sign Up", "/signup", "Already have an account? <a href='/login'>Sign in</a>", error))
  end

  # ... (other methods stay same, so I should just do the target content properly)
  # Wait, wait, let me just replace the parts:

  def login_post(conn) do
    email = conn.params["email"]
    password = conn.params["password"]

    user = Repo.get_by(User, email: email)
    if user && user.password_hash == User.hash_password(password) do
      conn
      |> put_session("user_id", user.id)
      |> redirect(to: "/todo")
    else
      redirect(conn, to: "/login?error=Invalid%20credentials")
    end
  end

  def signup_post(conn) do
    email = conn.params["email"]
    password = conn.params["password"]
    
    username = String.split(email, "@") |> List.first()

    changeset = User.changeset(%User{}, %{
      email: email,
      username: username || "user",
      password_hash: User.hash_password(password)
    })

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_session("user_id", user.id)
        |> redirect(to: "/todo")
      {:error, _} ->
        redirect(conn, to: "/signup?error=Email%20already%20taken")
    end
  end

  def logout(conn) do
    conn
    |> put_session("user_id", nil)
    |> redirect(to: "/login")
  end

  defp render_page(conn, title, action, toggle_link, error_msg) do
    error_html = if error_msg != "", do: "<div class='auth-error'>#{error_msg}</div>", else: ""
    
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>#{title} — Todo App</title>
      <link rel="stylesheet" href="/assets/todo.css" />
    </head>
    <body class="auth-body">
      <div class="auth-container">
        <h1>#{title}</h1>
        #{error_html}
        <form method="POST" action="#{action}" class="auth-form">
          #{csrf_token_tag(conn)}
          <input type="email" name="email" placeholder="Email address" required />
          <input type="password" name="password" placeholder="Password" required />
          <button type="submit">#{title}</button>
        </form>
        <p class="auth-toggle">#{toggle_link}</p>
      </div>
    </body>
    </html>
    """
  end
end
