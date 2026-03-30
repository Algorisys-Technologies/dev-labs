defmodule TodoApp.TodoHTML do
  require Ignite.LiveView
  import Ignite.LiveView, only: [sigil_F: 2]

  def todo_item(assigns) do
    ~F"""
    <div class="todo-item <%= if @status == "completed", do: "completed", else: "" %>" id="todo-<%= @todo.id %>">
      <div class="todo-content">
        <label class="checkbox-container">
          <input type="checkbox" 
                 <%= if @status == "completed", do: "checked", else: "" %> 
                 ignite-click="toggle-todo" 
                 ignite-value="<%= @todo.id %>" />
          <span class="checkmark"></span>
        </label>
        
        <div class="todo-text">
          <h3 class="<%= if @status == "completed", do: "text-strike", else: "" %>"><%= @todo.title %></h3>
        </div>
      </div>

      <div class="todo-meta">
        <%= if @todo.bookmarked do %>
          <span class="bookmarked" style="color: #f1c40f;">⭐</span>
        <% end %>
        <%= if @todo.category do %>
          <span class="category-badge" style="background-color: #3498db; color: white; padding: 2px 6px; border-radius: 4px;">
            <%= @todo.category.name %>
          </span>
        <% end %>
        <button class="delete-btn" ignite-click="delete-todo" ignite-value="<%= @todo.id %>">&times;</button>
      </div>
    </div>
    """
  end

  def new_todo_form(_assigns) do
    ~F"""
    <form ignite-submit="add-todo" class="new-todo-form">
      <input type="text" name="title" placeholder="What needs to be done?" required class="todo-input" />
      <div class="form-actions">
        <button type="submit" class="submit-btn">Add Task</button>
      </div>
    </form>
    """
  end
end
