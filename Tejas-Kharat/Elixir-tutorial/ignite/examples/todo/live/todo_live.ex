defmodule MyApp.TodoLive do
  use Ignite.LiveView
  alias MyApp.{Repo, TodoItem, Category, Subtask, TodoUser}
  import Ecto.Query

  @impl true
  def mount(_params, _session) do
    seed_data()
    user_id = 1
    categories = Repo.all(Category)

    todos =
      TodoItem
      |> where([t], t.user_id == ^user_id)
      |> order_by([t], desc: t.inserted_at)
      |> preload([:category, :subtasks])
      |> Repo.all()

    total = length(todos)
    done = Enum.count(todos, &(&1.status == "completed"))
    
    # Modern greeting context
    date_str = Calendar.strftime(DateTime.utc_now(), "%a %d %b %Y")

    assigns = %{
      user_id: user_id,
      categories: categories,
      total: total,
      done: done,
      current_date: date_str,
      filter: "all"
    }

    assigns =
      stream(assigns, :todos, todos,
        limit: 50,
        render: fn todo ->
          MyApp.TodoHTML.todo_item(%{todo: todo})
          |> Ignite.LiveView.Rendered.to_html()
        end
      )

    {:ok, assigns}
  end

  # --- Events ---

  @impl true
  def handle_event("add-todo", params, assigns) do
    title = Map.get(params, "title", "")
    cat_id = Map.get(params, "category_id", "")
    priority = Map.get(params, "priority", "medium")

    if String.trim(title) != "" do
      category_id =
        if cat_id != "" do
          cid = String.to_integer(cat_id)
          if Repo.get(Category, cid), do: cid, else: nil
        else
          nil
        end

      attrs = %{
        title: String.trim(title),
        user_id: assigns.user_id,
        priority: priority,
        category_id: category_id
      }

      case %TodoItem{} |> TodoItem.changeset(attrs) |> Repo.insert() do
        {:ok, todo} ->
          updated = stream_insert(assigns, :todos, Repo.preload(todo, [:category, :subtasks]), at: 0)
          updated = %{updated | total: assigns.total + 1}
          {:noreply, updated}

        {:error, _changeset} ->
          {:noreply, assigns}
      end
    else
      {:noreply, assigns}
    end
  rescue
    _ -> {:noreply, assigns}
  end

  @impl true
  def handle_event("toggle-todo", %{"value" => id}, assigns) do
    todo = Repo.get!(TodoItem, to_int(id))
    new_status = if todo.status == "completed", do: "pending", else: "completed"

    {:ok, updated} =
      todo
      |> TodoItem.changeset(%{status: new_status})
      |> Repo.update()

    done_delta = if new_status == "completed", do: 1, else: -1
    updated_assigns = stream_insert(assigns, :todos, Repo.preload(updated, [:category, :subtasks]))
    updated_assigns = %{updated_assigns | done: assigns.done + done_delta}
    {:noreply, updated_assigns}
  end

  @impl true
  def handle_event("delete-todo", %{"value" => id}, assigns) do
    todo = Repo.get(TodoItem, to_int(id))
    if todo do
      was_done = todo.status == "completed"
      Repo.delete!(todo)
      updated = stream_delete(assigns, :todos, todo)
      updated = %{updated | total: assigns.total - 1}
      updated = if was_done, do: %{updated | done: assigns.done - 1}, else: updated
      {:noreply, updated}
    else
      {:noreply, assigns}
    end
  end

  @impl true
  def handle_event("filter", %{"value" => status}, assigns) do
    todos =
      TodoItem
      |> where([t], t.user_id == ^assigns.user_id)
      |> filter_query(status)
      |> order_by([t], desc: t.inserted_at)
      |> preload([:category, :subtasks])
      |> Repo.all()

    updated =
      assigns
      |> Map.put(:filter, status)
      |> stream(:todos, todos,
        reset: true,
        render: fn todo ->
          MyApp.TodoHTML.todo_item(%{todo: todo})
          |> Ignite.LiveView.Rendered.to_html()
        end
      )

    {:noreply, updated}
  end

  @impl true
  def handle_event("add-subtask", %{"todo_id" => tid, "title" => title}, assigns) do
    if String.trim(title) != "" do
      attrs = %{
        title: String.trim(title),
        todo_item_id: to_int(tid),
        completed: false
      }

      case %Subtask{} |> Subtask.changeset(attrs) |> Repo.insert() do
        {:ok, _sub} ->
          todo =
            Repo.get!(TodoItem, to_int(tid)) |> Repo.preload([:category, :subtasks])

          {:noreply, stream_insert(assigns, :todos, todo)}

        {:error, _changeset} ->
          {:noreply, assigns}
      end
    else
      {:noreply, assigns}
    end
  end

  @impl true
  def handle_event("toggle-subtask", %{"id" => id, "todo_id" => tid}, assigns) do
    sub = Repo.get!(Subtask, to_int(id))
    {:ok, _} = sub |> Subtask.changeset(%{completed: !sub.completed}) |> Repo.update()
    todo = Repo.get!(TodoItem, to_int(tid)) |> Repo.preload([:category, :subtasks])
    {:noreply, stream_insert(assigns, :todos, todo)}
  end

  # --- Helper functions ---

  defp filter_query(query, "pending"), do: where(query, [t], t.status == "pending")
  defp filter_query(query, "completed"), do: where(query, [t], t.status == "completed")
  defp filter_query(query, _), do: query

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: nil

  # --- Render ---

  @impl true
  def render(assigns) do
    ~F"""
    <div class="todo-header">
      <div class="hero-content">
        <h1>Task Center</h1>
        <p class="hero-date"><%= @current_date %></p>
      </div>
      <div class="header-stats">
        <div class="stat-chip">
          <span class="stat-label">Total</span>
          <span class="stat-val"><%= @total %></span>
        </div>
        <div class="stat-chip">
          <span class="stat-label">Done</span>
          <span class="stat-val done"><%= @done %></span>
        </div>
      </div>
    </div>
    
    <div class="todo-body" data-filter="<%= @filter %>">
      <form ignite-submit="add-todo" class="add-form">
        <div class="add-main">
          <input type="text" name="title" placeholder="Create a new task..." autofocus autocomplete="off" class="task-input" />
          <button type="submit" class="add-btn">
            Add Task
          </button>
        </div>
        <div class="add-meta">
          <%= MyApp.TodoHTML.category_select(assigns) %>
          <%= MyApp.TodoHTML.priority_select() %>
        </div>
      </form>
      
      <div class="todo-filters">
        <button ignite-click="filter" ignite-value="all" class="<%= "filter-btn #{if @filter == "all", do: "active"}" %>">
          All
        </button>
        <button ignite-click="filter" ignite-value="pending" class="<%= "filter-btn #{if @filter == "pending", do: "active"}" %>">
          Pending
        </button>
        <button ignite-click="filter" ignite-value="completed" class="<%= "filter-btn #{if @filter == "completed", do: "active"}" %>">
          Completed
        </button>
      </div>

      <div ignite-stream="todos" class="todo-list">
      </div>
    </div>
    """
  end

  # --- Seed helpers ---

  defp seed_data do
    unless Repo.get(TodoUser, 1) do
      %TodoUser{id: 1}
      |> TodoUser.changeset(%{email: "demo@ignite.dev", password: "password"})
      |> Repo.insert!()
    end

    if Repo.all(Category) == [] do
      Repo.insert!(%Category{name: "Work", color: "#818cf8"})
      Repo.insert!(%Category{name: "Personal", color: "#34d399"})
      Repo.insert!(%Category{name: "Urgent", color: "#fb7185"})
    end
  end
end
