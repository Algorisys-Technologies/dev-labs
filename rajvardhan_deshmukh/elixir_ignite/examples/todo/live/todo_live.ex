defmodule TodoApp.TodoLive do
  use Ignite.LiveView
  import Ecto.Query

  alias MyApp.Repo
  alias TodoApp.TodoItem
  alias TodoApp.User

  @impl true
  def mount(_params, _session) do
    user_id = 1
    ensure_dummy_user_exists(user_id)

    todos = Repo.all(
      from t in TodoItem, 
      where: t.user_id == ^user_id,
      preload: [:category, :subtasks]
    )

    assigns = 
      %{
        user_id: user_id,
        filter: "all"
      }
      |> stream(:todos, todos, 
        limit: 100,
        render: fn item ->
          Ignite.LiveView.FEExEngine.escape(TodoApp.TodoHTML.todo_item(%{todo: item, status: item.status}))
        end
      )

    {:ok, assigns}
  end

  @impl true
  def handle_event("add-todo", %{"title" => title}, assigns) do
    attrs = %{
      title: title,
      user_id: assigns.user_id,
      status: "pending",
      bookmarked: false
    }

    case Repo.insert(TodoItem.changeset(%TodoItem{}, attrs)) do
      {:ok, item} ->
        item = Repo.preload(item, [:category, :subtasks])
        updated_assigns = stream_insert(assigns, :todos, item, at: 0)
        {:noreply, updated_assigns}

      {:error, _changeset} ->
        {:noreply, assigns}
    end
  end

  @impl true
  def handle_event("toggle-todo", %{"value" => id_str}, assigns) do
    id = String.to_integer(id_str)

    item = Repo.get(TodoItem, id) |> Repo.preload([:category, :subtasks])
    new_status = if item.status == "completed", do: "pending", else: "completed"
    
    {:ok, updated_item} = item
    |> TodoItem.changeset(%{status: new_status})
    |> Repo.update()

    {:noreply, stream_insert(assigns, :todos, updated_item)}
  end

  @impl true
  def handle_event("delete-todo", %{"value" => id_str}, assigns) do
    id = String.to_integer(id_str)
    
    item = Repo.get(TodoItem, id)
    if item do
      Repo.delete(item)
    end

    {:noreply, stream_delete(assigns, :todos, item)}
  end

  @impl true
  def handle_event("filter", %{"value" => status}, assigns) do
    query = from t in TodoItem, 
            where: t.user_id == ^assigns.user_id,
            preload: [:category, :subtasks]

    query = 
      if status == "all" do
        query
      else
        from t in query, where: t.status == ^status
      end

    todos = Repo.all(query)
    
    assigns = 
      assigns
      |> Map.put(:filter, status)
      |> stream(:todos, todos, reset: true)

    {:noreply, assigns}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="todo-app">
      <header>
        <h1>Ignite Tasks</h1>
        <div class="filter-tabs">
          <button ignite-click="filter" ignite-value="all" class="<%= if @filter == "all", do: "active", else: "" %>">All</button>
          <button ignite-click="filter" ignite-value="pending" class="<%= if @filter == "pending", do: "active", else: "" %>">Pending</button>
          <button ignite-click="filter" ignite-value="completed" class="<%= if @filter == "completed", do: "active", else: "" %>">Completed</button>
        </div>
      </header>
      
      <form ignite-submit="add-todo" class="new-todo-form">
        <input type="text" name="title" placeholder="What needs to be done?" required class="todo-input" />
        <div class="form-actions">
          <button type="submit" class="submit-btn">Add Task</button>
        </div>
      </form>

      <div class="todo-list" ignite-stream="todos">
      </div>
      
      <footer>
        <p>Built with ❤️ using Ignite LiveView Streams & FEEx Templates</p>
      </footer>
    </div>
    """
  end

  defp ensure_dummy_user_exists(id) do
    if Repo.get(User, id) == nil do
      Repo.insert!(%User{
        id: id,
        username: "demo_user",
        email: "demo@ignite.dev",
        password_hash: "dummyhash"
      })
    end
  end
end
