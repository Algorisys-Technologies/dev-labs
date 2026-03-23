defmodule MyApp.TodoHTML do
  @moduledoc "Premium V2 HTML components for the Todo App."

  def todo_item(assigns) do
    todo = assigns.todo
    id = todo.id
    title = esc(todo.title)
    status = todo.status
    priority = todo.priority
    category = todo.category
    inserted = todo.inserted_at

    done? = status == "completed"
    item_class = if done?, do: "todo-item completed", else: "todo-item"
    check_class = if done?, do: "check-box done", else: "check-box"
    title_class = if done?, do: "todo-title struck", else: "todo-title"
    # Use a modern checkmark icon
    check_icon = if done?, do: "✓", else: ""

    # Category Badge
    cat_html =
      if category do
        c = esc(category.color)
        n = esc(category.name)
        # Using the new tag-cat class
        ~s(<span class="tag-cat" style="color:#{c};background:#{c}10;border-color:#{c}30">#{n}</span>)
      else
        ""
      end

    # Time display (Monospace)
    time_str =
      if inserted do
        "#{String.pad_leading("#{inserted.hour}", 2, "0")}:#{String.pad_leading("#{inserted.minute}", 2, "0")}"
      else
        ""
      end

    {:safe, """
    <div id="todos-#{id}" class="#{item_class}">
      <div ignite-click="toggle-todo" ignite-value="#{id}" class="#{check_class}">#{check_icon}</div>
      <div class="todo-content">
        <div class="todo-main">
          <span class="#{title_class}">#{title}</span>
          <div class="todo-tags">
            #{cat_html}
            <div class="tag-priority pri-#{priority}"></div>
          </div>
        </div>
        <div class="todo-footer">
          <span class="todo-time">#{time_str}</span>
        </div>
      </div>
      <button ignite-click="delete-todo" ignite-value="#{id}" class="delete-btn" title="Delete">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path>
        </svg>
      </button>
    </div>
    """}
  end

  def category_select(assigns) do
    cats = assigns[:categories] || []

    options =
      Enum.map_join(cats, "\n", fn cat ->
        ~s(<option value="#{cat.id}">#{esc(cat.name)}</option>)
      end)

    {:safe, """
    <select name="category_id" class="meta-select">
      <option value="">📁 Select Category</option>
      #{options}
    </select>
    """}
  end

  def priority_select do
    {:safe, """
    <select name="priority" class="meta-select">
      <option value="medium">⚡ Medium Priority</option>
      <option value="high">🔥 High Priority</option>
      <option value="low">❄️ Low Priority</option>
    </select>
    """}
  end

  defp esc(nil), do: ""
  defp esc(val) when is_binary(val) do
    val
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
  defp esc(val), do: esc(to_string(val))
end
