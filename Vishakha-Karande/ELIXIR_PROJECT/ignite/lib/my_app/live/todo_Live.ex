defmodule MyApp.TodoLive do
  @moduledoc """
  Todo App — Capstone LiveView showcasing Ignite framework features:
  • Streams (Step 25) — efficient list rendering
  • PubSub (Step 18) — real-time sync across tabs
  • LiveComponent (Step 24) — subtask panel
  • FEEx ~F (Step 42) — clean category bar template
  """
  use Ignite.LiveView
  import Ecto.Query
  alias MyApp.{Repo, TodoItem, Category}

  @topic "todos"

  @impl true
  def mount(_params, _session) do
    # PubSub: subscribe so other tabs' changes appear here
    subscribe(@topic)

    todos = Repo.all(from t in TodoItem, order_by: [desc: t.inserted_at])
            |> Repo.preload([:category, :subtasks])
    categories = Repo.all(Category)

    assigns = %{
      categories: categories,
      filter: "all",
      category_filter: nil,
      expanded_todo: nil,
      todo_count: length(todos),
      done_count: Enum.count(todos, &(&1.completed || &1.status == "done"))
    }

    # Streams: Initialize :todos stream with a render function
    assigns = stream(assigns, :todos, todos, render: &render_todo_row/1)

    {:ok, assigns}
  end

  # ── Events ──────────────────────────────────────────────

  @impl true
  def handle_event("add-todo", %{"title" => title} = params, assigns) when title != "" do
    category_id = case Map.get(params, "category_id", "") do
      "" -> nil
      id -> String.to_integer(id)
    end

    changeset = TodoItem.changeset(%TodoItem{}, %{
      title: title,
      status: "pending",
      priority: "medium",
      category_id: category_id
    })
    {:ok, todo} = Repo.insert(changeset)
    todo = Repo.preload(todo, [:category, :subtasks])

    assigns = assigns
      |> stream_insert(:todos, todo, at: 0)
      |> Map.put(:todo_count, assigns.todo_count + 1)

    # PubSub: Broadcast to other tabs
    broadcast(@topic, {:todo_added, todo})

    {:noreply, assigns}
  end

  def handle_event("add-todo", _params, assigns), do: {:noreply, assigns}

  @impl true
  def handle_event("toggle-todo", %{"value" => id}, assigns) do
    id_int = String.to_integer(id)
    todo = Repo.get!(TodoItem, id_int) |> Repo.preload([:category, :subtasks])
    new_completed = !todo.completed
    new_status = if new_completed, do: "done", else: "pending"
    {:ok, updated} = Repo.update(TodoItem.changeset(todo, %{completed: new_completed, status: new_status}))
    updated = Repo.preload(updated, [:category, :subtasks])

    done_delta = if new_completed, do: 1, else: -1
    assigns = assigns
      |> stream_insert(:todos, updated)
      |> Map.put(:done_count, assigns.done_count + done_delta)

    broadcast(@topic, {:todo_toggled, updated})
    {:noreply, assigns}
  end

  @impl true
  def handle_event("delete-todo", %{"value" => id}, assigns) do
    id_int = String.to_integer(id)
    todo = Repo.get!(TodoItem, id_int) |> Repo.preload([:category, :subtasks])
    Repo.delete!(todo)

    was_done = todo.completed || todo.status == "done"
    assigns = assigns
      |> stream_delete(:todos, todo)
      |> Map.put(:todo_count, assigns.todo_count - 1)
      |> Map.put(:done_count, if(was_done, do: assigns.done_count - 1, else: assigns.done_count))

    broadcast(@topic, {:todo_deleted, todo})
    {:noreply, assigns}
  end

  @impl true
  def handle_event("filter", %{"value" => status}, assigns) do
    # Re-query with filters applied
    assigns = apply_filters(%{assigns | filter: status})
    {:noreply, assigns}
  end

  @impl true
  def handle_event("filter-category", %{"value" => cat_id}, assigns) do
    cat_filter = case cat_id do
      "all" -> nil
      id -> String.to_integer(id)
    end
    assigns = apply_filters(%{assigns | category_filter: cat_filter})
    {:noreply, assigns}
  end

  @impl true
  def handle_event("expand-todo", %{"value" => id}, assigns) do
    id_int = String.to_integer(id)
    new_expanded = if assigns.expanded_todo == id_int, do: nil, else: id_int
    {:noreply, %{assigns | expanded_todo: new_expanded}}
  end

  # ── PubSub: Receive broadcasts from other tabs ──────────

  @impl true
  def handle_info({:pubsub, @topic, {:todo_added, todo}}, assigns) do
    assigns = assigns
      |> stream_insert(:todos, todo, at: 0)
      |> Map.put(:todo_count, assigns.todo_count + 1)
    {:noreply, assigns}
  end

  def handle_info({:pubsub, @topic, {:todo_toggled, todo}}, assigns) do
    assigns = stream_insert(assigns, :todos, todo)
    {:noreply, assigns}
  end

  def handle_info({:pubsub, @topic, {:todo_deleted, todo}}, assigns) do
    assigns = stream_delete(assigns, :todos, todo)
    {:noreply, assigns}
  end

  def handle_info(_msg, assigns), do: {:noreply, assigns}

  # ── Render ──────────────────────────────────────────────

  @impl true
  def render(assigns) do
    pending_count = assigns.todo_count - assigns.done_count

    category_tabs = assigns.categories |> Enum.map(fn cat ->
      active = if assigns.category_filter == cat.id, do: " active", else: ""
      """
      <button class="category-tab#{active}"
              style="--cat-color: #{cat.color};"
              ignite-click="filter-category" ignite-value="#{cat.id}">
        <span class="category-dot" style="background: #{cat.color};"></span>
        #{html_escape(cat.name)}
      </button>
      """
    end) |> Enum.join("")

    all_active = if assigns.category_filter == nil, do: " active", else: ""

    category_options = assigns.categories |> Enum.map(fn cat ->
      "<option value=\"#{cat.id}\">#{html_escape(cat.name)}</option>"
    end) |> Enum.join("")

    # Subtask panel for expanded todo
    subtask_html = if assigns.expanded_todo do
      live_component(assigns, MyApp.SubtaskComponent, id: "subtasks-#{assigns.expanded_todo}", todo_id: assigns.expanded_todo)
    else
      ""
    end

    """
    <link rel="stylesheet" href="/assets/todo.css" />
    <div class="todo-app">
      <div class="todo-header">
        <h1>📝 Todo App</h1>
        <div class="todo-stats">
          <span class="stat stat-total">#{assigns.todo_count} total</span>
          <span class="stat stat-pending">#{pending_count} pending</span>
          <span class="stat stat-done">#{assigns.done_count} done</span>
        </div>
      </div>

      <div class="category-bar">
        <button class="category-tab#{all_active}"
                ignite-click="filter-category" ignite-value="all">
          All
        </button>
        #{category_tabs}
      </div>

      <form ignite-submit="add-todo" class="todo-form">
        <input name="title" placeholder="Add a new todo..." autocomplete="off" />
        <select name="category_id" class="category-select">
          <option value="">No category</option>
          #{category_options}
        </select>
        <button type="submit">Add</button>
      </form>

      <div class="filter-bar">
        <button class="filter-btn#{if assigns.filter == "all", do: " active"}" ignite-click="filter" ignite-value="all">All</button>
        <button class="filter-btn#{if assigns.filter == "pending", do: " active"}" ignite-click="filter" ignite-value="pending">Pending</button>
        <button class="filter-btn#{if assigns.filter == "done", do: " active"}" ignite-click="filter" ignite-value="done">Done</button>
      </div>

      <div ignite-stream="todos" class="todo-list">
      </div>

      #{subtask_html}
    </div>
    """
  end

  # ── Helpers ─────────────────────────────────────────────

  defp apply_filters(assigns) do
    query = from t in TodoItem, order_by: [desc: t.inserted_at]

    query = case assigns.filter do
      "done"    -> from t in query, where: t.completed == true or t.status == "done"
      "pending" -> from t in query, where: t.completed == false and t.status != "done"
      _         -> query
    end

    query = case assigns.category_filter do
      nil -> query
      cat_id -> from t in query, where: t.category_id == ^cat_id
    end

    todos = Repo.all(query) |> Repo.preload([:category, :subtasks])

    # Reset stream with new filtered results
    stream(assigns, :todos, todos, render: &render_todo_row/1, reset: true)
  end

  defp render_todo_row(todo) do
    done? = todo.completed || todo.status == "done"
    completed_class = if done?, do: " completed", else: ""
    checked = if done?, do: "checked", else: ""
    deco = if done?, do: "line-through", else: "none"

    cat_dot = if todo.category do
      "<span class=\"category-dot\" style=\"background: #{todo.category.color};\"></span>"
    else
      ""
    end

    cat_name = if todo.category, do: todo.category.name, else: ""

    subtask_count = length(todo.subtasks || [])
    subtask_done = Enum.count(todo.subtasks || [], & &1.completed)
    subtask_badge = if subtask_count > 0 do
      "<span class=\"subtask-badge\">📋 #{subtask_done}/#{subtask_count}</span>"
    else
      ""
    end

    """
    <div id="todos-#{todo.id}" class="todo-item#{completed_class}">
      <input type="checkbox" class="todo-checkbox" #{checked}
             ignite-click="toggle-todo" ignite-value="#{todo.id}" />
      #{cat_dot}
      <span class="todo-title" style="text-decoration: #{deco};">#{html_escape(todo.title)}</span>
      <span class="category-label">#{html_escape(cat_name)}</span>
      #{subtask_badge}
      <span class="priority-#{todo.priority}">#{todo.priority}</span>
      <button class="expand-btn" ignite-click="expand-todo" ignite-value="#{todo.id}">📋</button>
      <button class="delete-btn" ignite-click="delete-todo" ignite-value="#{todo.id}">🗑</button>
    </div>
    """
  end

  defp html_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
  defp html_escape(nil), do: ""
end
