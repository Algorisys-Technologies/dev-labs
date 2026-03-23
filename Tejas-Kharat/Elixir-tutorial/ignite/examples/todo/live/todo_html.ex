defmodule MyApp.TodoHTML do
  import Ignite.LiveView
  @moduledoc "Premium HTML components for the Todo App."

  def todo_item(assigns) do
    ~F"""
    <div id="<%= "todos-#{@todo.id}" %>" class="todo-entry-wrapper">
      <div class="<%= "todo-item #{if @todo.status == "completed", do: "completed"}" %>">
        <div ignite-click="toggle-todo"
             ignite-value="<%= @todo.id %>"
             class="<%= "check-box #{if @todo.status == "completed", do: "done"}" %>">
          <%= if @todo.status == "completed" do %>✓<% end %>
        </div>

        <div class="todo-content">
          <div class="todo-main">
            <span class="<%= "todo-title #{if @todo.status == "completed", do: "struck"}" %>">
              <%= @todo.title %>
            </span>
            <div class="todo-badges">
              <%= if @todo.category do %>
                <span class="cat-badge"
                      style="<%= "background:#{@todo.category.color}15;color:#{@todo.category.color};border:1px solid #{@todo.category.color}30" %>">
                  <%= @todo.category.name %>
                </span>
              <% end %>
            <span class="<%= "pri-badge pri-#{@todo.priority}" %>" title="<%= "#{@todo.priority} priority" %>">
                <%= case to_string(@todo.priority) do
                  "high" -> "🔴"
                  "low" -> "🟢"
                  _ -> "🟡"
                end %>
              </span>
            </div>
          </div>
          <span class="todo-time">
            <%= if @todo.inserted_at do
              "#{String.pad_leading("#{@todo.inserted_at.hour}", 2, "0")}:#{String.pad_leading("#{@todo.inserted_at.minute}", 2, "0")}"
            end %>
          </span>
        </div>

        <div class="todo-actions">
          <button ignite-click="delete-todo" ignite-value="<%= @todo.id %>" class="delete-btn" title="Delete task">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M2 4h12M5 4V3a1 1 0 011-1h4a1 1 0 011 1v1M6 7v5M10 7v5M3 4l1 9a1 1 0 001 1h6a1 1 0 001-1l1-9"/>
            </svg>
          </button>
        </div>
      </div>

      <%= if length(@todo.subtasks || []) > 0 or @todo.status != "completed" do %>
        <div class="subtasks-container">
          <div class="subtask-list">
            <%= for sub <- @todo.subtasks || [] do %>
              <div class="subtask-item">
                <div ignite-click="toggle-subtask" 
                     ignite-value="<%= sub.id %>" 
                     class="<%= "sub-check #{if sub.completed, do: "done"}" %>"
                     ignite-params="<%= Jason.encode!(%{id: sub.id, todo_id: @todo.id}) %>">
                  <%= if sub.completed, do: "✓", else: "" %>
                </div>
                <span class="<%= "sub-title #{if sub.completed, do: "struck"}" %>"><%= sub.title %></span>
              </div>
            <% end %>
          </div>
          
          <%= if @todo.status != "completed" do %>
            <form ignite-submit="add-subtask" class="subtask-form">
              <input type="hidden" name="todo_id" value="<%= @todo.id %>" />
              <input type="text" name="title" placeholder="Add subtask..." class="sub-input" autocomplete="off" />
              <button type="submit" class="sub-add-btn">+</button>
            </form>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def category_select(assigns) do
    ~F"""
    <select name="category_id" class="meta-select">
      <option value="">📁 Category</option>
      <%= for cat <- @categories do %>
        <option value={cat.id}><%= cat.name %></option>
      <% end %>
    </select>
    """
  end

  def priority_select do
    ~F"""
    <select name="priority" class="meta-select">
      <option value="medium">🟡 Medium</option>
      <option value="high">🔴 High</option>
      <option value="low">🟢 Low</option>
    </select>
    """
  end
end
