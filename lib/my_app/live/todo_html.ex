defmodule MyApp.TodoHTML do
  @moduledoc """
  FEEx template components for the Todo App.
  Uses the ~F sigil from Ignite's FEEx engine (Step 42).

  These are standalone function components — they are NOT a LiveView
  and therefore do NOT need mount/2 or render/1 callbacks.
  """

  import Ignite.LiveView, only: [sigil_F: 2]

  @doc "Renders the add-todo form"
  def todo_form(_assigns) do
    ~F"""
    <div class="todo-form">
      <form ignite-submit="add-todo" style="display:flex;gap:12px;width:100%;">
        <input name="title" placeholder="Add a new todo..." autocomplete="off"
               style="flex:1;padding:10px 16px;border-radius:8px;border:1px solid #ddd;font-size:15px;" />
        <button type="submit"
                style="padding:10px 20px;background:#5c6bc0;color:white;border:none;border-radius:8px;cursor:pointer;font-size:15px;">
          Add
        </button>
      </form>
    </div>
    """
  end

  @doc "Renders a single todo item row"
  def todo_item(assigns) do
    todo = assigns.todo
    done? = todo.completed || todo.status == "done"
    completed_class = if done?, do: " completed", else: ""
    title_deco = if done?, do: "line-through", else: "none"
    checked = if done?, do: "checked", else: ""

    """
    <div class="todo-item#{completed_class}">
      <input type="checkbox" class="todo-checkbox" #{checked}
             ignite-click="toggle-todo" ignite-value="#{todo.id}" />
      <span class="todo-title" style="text-decoration:#{title_deco};">#{escape(todo.title)}</span>
      <span class="priority-#{todo.priority}">#{todo.priority}</span>
      <button class="delete-btn" ignite-click="delete-todo" ignite-value="#{todo.id}">🗑</button>
    </div>
    """
  end

  @doc "Renders the filter bar with All, Pending, Done buttons"
  def filter_bar(assigns) do
    all_active = if assigns.filter == "all", do: " active", else: ""
    pending_active = if assigns.filter == "pending", do: " active", else: ""
    done_active = if assigns.filter == "done", do: " active", else: ""

    """
    <div class="filter-bar">
      <button class="filter-btn#{all_active}" ignite-click="filter" ignite-value="all">All</button>
      <button class="filter-btn#{pending_active}" ignite-click="filter" ignite-value="pending">Pending</button>
      <button class="filter-btn#{done_active}" ignite-click="filter" ignite-value="done">Done</button>
    </div>
    """
  end

  defp escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
  defp escape(nil), do: ""
end
