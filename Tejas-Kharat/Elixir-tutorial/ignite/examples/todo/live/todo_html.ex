defmodule MyApp.TodoHTML do
  @moduledoc """
  HTML rendering functions for the Todo app LiveView.
  Uses ~F (Flame EEx) templates for clean, auto-escaped rendering.
  NOTE: ~F does NOT support Phoenix HEEX-style {...} attributes.
  Use standard <%= ... %> interpolation inside attribute strings.
  """

  import Ignite.LiveView, only: [sigil_F: 2, raw: 1]
  alias MyApp.{Category, TodoItem}

  # ═══════════════════════════════════════════════════════════════════
  # Entry Points
  # ═══════════════════════════════════════════════════════════════════

  def render_auth(assigns) do
    ~F"""
    <div id="todo-auth" class="auth-container">
      <div class="auth-card">
        <%= if @auth_mode == :register do %>
          <h1 class="auth-title">Create Account</h1>
          <p class="auth-subtitle">Start organizing your tasks</p>
          <form action="/todo/register" method="POST">
            <input type="hidden" name="_csrf_token" value="<%= @csrf_token %>" />
            <div class="form-group">
              <label class="form-label">Username</label>
              <input class="form-input <%= error_class(@auth_errors, "username") %>" type="text" name="username" placeholder="Your name" />
              <%= raw(error_tag(@auth_errors, "username")) %>
            </div>
            <div class="form-group">
              <label class="form-label">Email</label>
              <input class="form-input <%= error_class(@auth_errors, "email") %>" type="email" name="email" placeholder="you@example.com" />
              <%= raw(error_tag(@auth_errors, "email")) %>
            </div>
            <div class="form-group">
              <label class="form-label">Password</label>
              <input class="form-input <%= error_class(@auth_errors, "password") %>" type="password" name="password" placeholder="Min 6 characters" />
              <%= raw(error_tag(@auth_errors, "password")) %>
            </div>
            <button class="btn btn-primary btn-full" type="submit">Create Account</button>
          </form>
          <p class="auth-switch">
            Already have an account?
            <button class="auth-switch-link" ignite-click="switch_auth">Sign in</button>
          </p>
        <% else %>
          <h1 class="auth-title">Welcome Back</h1>
          <p class="auth-subtitle">Sign in to your account</p>
          <form action="/todo/login" method="POST">
            <input type="hidden" name="_csrf_token" value="<%= @csrf_token %>" />
            <div class="form-group">
              <label class="form-label">Email</label>
              <input class="form-input <%= error_class(@auth_errors, "email") %>" type="email" name="email" placeholder="you@example.com" />
              <%= raw(error_tag(@auth_errors, "email")) %>
            </div>
            <div class="form-group">
              <label class="form-label">Password</label>
              <input class="form-input <%= error_class(@auth_errors, "password") %>" type="password" name="password" placeholder="Your password" />
              <%= raw(error_tag(@auth_errors, "password")) %>
            </div>
            <button class="btn btn-primary btn-full" type="submit">Sign In</button>
          </form>
          <p class="auth-switch">
            Don't have an account?
            <button class="auth-switch-link" ignite-click="switch_auth">Create one</button>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  def render_app(assigns, counts) do
    ~F"""
    <div id="todo-app" class="todo-app">
      <%= render_header(assigns) %>
      <%= render_toolbar(assigns) %>
      <%= render_filter_bar(assigns, counts) %>
      <%= render_add_form(assigns) %>
      <%= render_bulk_bar(assigns) %>
      <%= render_todo_list(assigns) %>
      <%= render_pagination(assigns) %>
      <%= render_subtask_panel(assigns) %>
      <%= render_category_manager(assigns) %>
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════
  # Section Renderers
  # ═══════════════════════════════════════════════════════════════════

  defp render_header(assigns) do
    ~F"""
    <header class="app-header">
      <h1 class="app-title">Todo App</h1>
      <div class="user-info">
        <span class="user-name"><%= @current_user.username %></span>
        <form action="/todo/logout" method="POST" style="display:inline; margin:0;">
          <input type="hidden" name="_csrf_token" value="<%= @csrf_token %>" />
          <button class="btn btn-ghost btn-sm" type="submit">Logout</button>
        </form>
      </div>
    </header>
    """
  end

  defp render_toolbar(assigns) do
    ~F"""
    <div class="toolbar">
      <form class="search-form" ignite-submit="search">
        <input class="search-input" type="text" name="search" value="<%= @search %>" placeholder="Search todos... (Enter to search)" />
        <button class="btn btn-secondary btn-sm" type="submit">Search</button>
        <%= if @search != "" do %>
          <button class="btn btn-ghost btn-sm" ignite-click="clear_search">Clear</button>
        <% end %>
      </form>
      <div class="toolbar-actions">
        <select class="form-select" name="category_filter" ignite-change="change" ignite-field="category_filter">
          <option value="" <%= if @category_filter == "", do: "selected" %>>All Categories</option>
          <%= for cat <- @categories do %>
            <option value="<%= cat.id %>" <%= if to_string(cat.id) == @category_filter, do: "selected" %>><%= cat.name %></option>
          <% end %>
        </select>
        <button class="btn btn-ghost btn-sm" ignite-click="toggle_category_mgmt">Manage</button>
      </div>
    </div>
    """
  end

  defp render_filter_bar(assigns, counts) do
    filters = [
      {"all", "All", counts.all},
      {"pending", "Pending", counts.pending},
      {"in_progress", "In Progress", counts.in_progress},
      {"completed", "Completed", counts.completed}
    ]

    ~F"""
    <div class="filter-bar">
      <div class="filter-group">
        <%= for {val, label, count} <- filters do %>
          <button class="filter-btn <%= if @filter == val, do: "filter-btn--active" %>" ignite-click="set_filter" ignite-value="<%= val %>"><%= label %> <span class="text-count">(<%= count %>)</span></button>
        <% end %>
      </div>
      <button class="bookmark-filter-btn <%= if @show_bookmarked, do: "bookmark-filter-btn--active" %>" ignite-click="toggle_bookmarked_filter">❤️ Favorites</button>
    </div>
    """
  end

  defp render_add_form(assigns) do
    ~F"""
    <form class="add-form" ignite-submit="add_todo">
      <input class="add-form__input" type="text" name="title" placeholder="What needs to be done?" value="" />
      <select class="add-form__select" name="category_id">
        <option value="">No category</option>
        <%= for cat <- @categories do %>
          <option value="<%= cat.id %>"><%= cat.name %></option>
        <% end %>
      </select>
      <button class="btn btn-primary" type="submit">Add</button>
    </form>
    """
  end

  defp render_bulk_bar(assigns) do
    count = MapSet.size(assigns.selected_ids)

    if count > 0 do
      ~F"""
      <div class="bulk-bar">
        <span class="bulk-bar__count"><%= count %> selected</span>
        <form ignite-submit="bulk_action" style="display:flex;gap:0.5rem;align-items:center;">
          <select class="bulk-bar__select" name="value">
            <option value="">-- Bulk Action --</option>
            <option value="mark_pending">Mark Pending</option>
            <option value="mark_in_progress">Mark In Progress</option>
            <option value="mark_completed">Mark Completed</option>
            <option value="delete">Delete Selected</option>
          </select>
          <button class="btn btn-sm btn-secondary" type="submit">Apply</button>
        </form>
      </div>
      """
    else
      ~F"""
      <div style="display:none;"></div>
      """
    end
  end

  # ═══════════════════════════════════════════════════════════════════
  # Todo List & Items
  # ═══════════════════════════════════════════════════════════════════

  defp render_todo_list(assigns) do
    if assigns.todos == [] do
      ~F"""
      <div class="empty-state">
        <div class="empty-state__icon">📋</div>
        <h3 class="empty-state__title">No todos found</h3>
        <p class="empty-state__text">Add a new todo above or adjust your filters.</p>
      </div>
      """
    else
      all_selected =
        length(assigns.todos) > 0 &&
          MapSet.size(assigns.selected_ids) == length(assigns.todos)

      ~F"""
      <div class="todo-list">
        <div class="todo-list-header">
          <input type="checkbox" class="todo-list-header__checkbox" ignite-click="toggle_select_all" <%= if all_selected, do: "checked" %> />
          <span>Todo List</span>
        </div>
        <%= for todo <- @todos do %>
          <%= render_todo_item(todo, assigns) %>
        <% end %>
      </div>
      """
    end
  end

  defp render_todo_item(todo, assigns) do
    cond do
      todo.id == assigns.editing_id -> render_todo_item_editing(todo, assigns)
      todo.id == assigns.confirm_delete_id -> render_todo_item_confirm(todo, assigns)
      true -> render_todo_item_normal(todo, assigns)
    end
  end

  defp render_todo_item_editing(todo, assigns) do
    ~F"""
    <div class="todo-item todo-item--editing todo-item--<%= todo.status %>">
      <form class="edit-form" ignite-submit="save_edit">
        <input class="edit-form__input" type="text" name="title" value="<%= @editing_title %>" />
        <button class="btn btn-primary btn-sm" type="submit">Save</button>
        <button class="btn btn-ghost btn-sm" type="button" ignite-click="cancel_edit">Cancel</button>
      </form>
    </div>
    """
  end

  defp render_todo_item_normal(todo, assigns) do
    selected = MapSet.member?(assigns.selected_ids, todo.id)
    title_class = if todo.status == "completed", do: "todo-item__title todo-item__title--done", else: "todo-item__title"

    ~F"""
    <div class="todo-item todo-item--<%= todo.status %> <%= if selected, do: "todo-item--selected" %>">
      <input type="checkbox" class="todo-item__checkbox" ignite-click="toggle_select" ignite-value="<%= todo.id %>" <%= if selected, do: "checked" %> />
      <button class="badge badge--<%= todo.status %>" ignite-click="cycle_status" ignite-value="<%= todo.id %>"><%= status_display(todo.status) %></button>
      <div class="todo-item__content">
        <span class="<%= title_class %>"><%= todo.title %></span>
        <div class="todo-item__meta">
          <%= if match?(%Category{}, todo.category) do %>
            <span class="badge badge--category"><%= todo.category.name %></span>
          <% end %>
          <%= render_subtask_btn(todo, assigns) %>
        </div>
      </div>
      <div class="todo-item__actions">
        <button class="heart-btn <%= if todo.bookmarked, do: "heart-btn--active" %>" ignite-click="toggle_bookmark" ignite-value="<%= todo.id %>">♥</button>
        <button class="btn-icon btn-icon--edit" ignite-click="start_edit" ignite-value="<%= todo.id %>" title="Edit">✏</button>
        <button class="btn-icon btn-icon--danger" ignite-click="confirm_delete" ignite-value="<%= todo.id %>" title="Delete">×</button>
      </div>
    </div>
    """
  end

  defp render_subtask_btn(todo, assigns) do
    count = length(todo.subtasks || [])
    if count > 0 do
      done = Enum.count(todo.subtasks, &(&1.status == "completed"))
      ~F"""
      <button class="subtask-count <%= if todo.id == @active_todo_id, do: "subtask-count--active" %>" ignite-click="show_subtasks" ignite-value="<%= todo.id %>"><%= done %>/<%= count %> subtasks</button>
      """
    else
      ~F"""
      <button class="subtask-count" ignite-click="show_subtasks" ignite-value="<%= todo.id %>">+ subtask</button>
      """
    end
  end

  defp render_todo_item_confirm(todo, assigns) do
    ~F"""
    <div class="todo-item todo-item--confirm">
      <div class="todo-item__content">
        <span class="todo-item__title">Delete: <%= todo.title %>?</span>
      </div>
      <div class="confirm-actions" style="display:flex;gap:0.5rem;">
        <button class="btn btn-danger btn-sm" ignite-click="delete_todo" ignite-value="<%= todo.id %>">Delete</button>
        <button class="btn btn-ghost btn-sm" ignite-click="cancel_delete">Cancel</button>
      </div>
    </div>
    """
  end

  defp render_pagination(assigns) do
    total_pages = max(1, ceil(assigns.total_count / assigns.per_page))
    page = assigns.page

    if total_pages <= 1 do
      ~F"""
      <div class="pagination">
        <div></div>
        <%= render_pagination_info(assigns) %>
      </div>
      """
    else
      ~F"""
      <div class="pagination">
        <div class="pagination__buttons">
          <button class="pagination__btn" ignite-click="set_page" ignite-value="<%= page - 1 %>" <%= if page <= 1, do: "disabled" %>>Prev</button>
          <%= for p <- page_range(page, total_pages) do %>
            <%= if p == :ellipsis do %>
              <span class="pagination__ellipsis">...</span>
            <% else %>
              <button class="pagination__btn <%= if p == page, do: 'pagination__btn--active' %>" ignite-click="set_page" ignite-value="<%= p %>"><%= p %></button>
            <% end %>
          <% end %>
          <button class="pagination__btn" ignite-click="set_page" ignite-value="<%= page + 1 %>" <%= if page >= total_pages, do: "disabled" %>>Next</button>
        </div>
        <%= render_pagination_info(assigns) %>
      </div>
      """
    end
  end

  defp render_pagination_info(assigns) do
    from = (assigns.page - 1) * assigns.per_page + 1
    to_val = min(assigns.page * assigns.per_page, assigns.total_count)

    ~F"""
    <div class="pagination__info">
      <span><%= from %>-<%= to_val %> of <%= @total_count %></span>
      <select class="pagination__select" name="per_page" ignite-change="change" ignite-field="per_page">
        <%= for n <- [5, 10, 25, 50] do %>
          <option value="<%= n %>" <%= if n == @per_page, do: "selected" %>><%= n %></option>
        <% end %>
      </select>
    </div>
    """
  end

  defp render_subtask_panel(assigns) do
    if assigns.active_todo_id == nil do
      ~F"""
      <div style="display:none;"></div>
      """
    else
      active_todo = Enum.find(assigns.todos, &(&1.id == assigns.active_todo_id))
      todo_title = if active_todo, do: active_todo.title, else: "Todo ##{assigns.active_todo_id}"

      ~F"""
      <div class="subtask-panel">
        <div class="subtask-panel__header">
          <h3 class="subtask-panel__title">Subtasks: <%= todo_title %></h3>
          <button class="btn btn-ghost btn-sm" ignite-click="show_subtasks" ignite-value="<%= @active_todo_id %>">Close</button>
        </div>
        <form class="subtask-form" ignite-submit="add_subtask">
          <input type="hidden" name="todo_id" value="<%= @active_todo_id %>" />
          <input class="subtask-form__input" type="text" name="title" placeholder="Add a subtask..." />
          <button class="btn btn-primary btn-sm" type="submit">Add</button>
        </form>
        <div class="subtask-list">
          <%= if @subtasks == [] do %>
            <p class="empty-text">No subtasks yet.</p>
          <% else %>
            <%= for st <- @subtasks do %>
              <%= render_subtask_item(st) %>
            <% end %>
          <% end %>
        </div>
        <%= render_subtask_progress(@subtasks) %>
      </div>
      """
    end
  end

  defp render_subtask_item(st) do
    done = st.status == "completed"
    ~F"""
    <div class="subtask-item">
      <input type="checkbox" class="subtask-item__checkbox" ignite-click="toggle_subtask" ignite-value="<%= st.id %>" <%= if done, do: "checked" %> />
      <span class="subtask-item__title <%= if done, do: "subtask-item__title--done" %>"><%= st.title %></span>
      <button class="btn-icon btn-icon--danger" ignite-click="delete_subtask" ignite-value="<%= st.id %>">✕</button>
    </div>
    """
  end

  defp render_subtask_progress([]) do
    ~F"""
    <div style="display:none;"></div>
    """
  end

  defp render_subtask_progress(subtasks) do
    total = length(subtasks)
    done = Enum.count(subtasks, &(&1.status == "completed"))
    pct = if total > 0, do: round(done / total * 100), else: 0
    ~F"""
    <div class="subtask-progress">
      <div class="subtask-progress__info"><%= done %>/<%= total %> completed (<%= pct %>%)</div>
      <div class="subtask-progress__bar">
        <div class="subtask-progress__fill" style="width: <%= pct %>%"></div>
      </div>
    </div>
    """
  end

  defp render_category_manager(assigns) do
    if !assigns.show_category_mgmt do
      ~F"""
      <div style="display:none;"></div>
      """
    else
      ~F"""
      <div class="overlay" ignite-click="toggle_category_mgmt"></div>
      <div class="category-panel">
        <div class="category-panel__header">
          <h2 class="category-panel__title">Manage Categories</h2>
          <button class="btn-icon" ignite-click="toggle_category_mgmt">✕</button>
        </div>
        <div class="category-panel__body">
          <form class="category-form" ignite-submit="add_category">
            <input class="category-form__input" type="text" name="name" placeholder="New category name..." />
            <button class="btn btn-primary btn-sm" type="submit">Add</button>
          </form>
          <div class="category-list">
            <%= for cat <- @categories do %>
              <%= if cat.id == @editing_category_id do %>
                <div class="category-item category-item--editing">
                  <form class="category-edit-form" ignite-submit="save_category">
                    <input class="category-form__input" type="text" name="name" value="<%= @editing_category_name %>" />
                    <button class="btn btn-primary btn-sm" type="submit">Save</button>
                    <button class="btn btn-ghost btn-sm" type="button" ignite-click="cancel_edit_category">Cancel</button>
                  </form>
                </div>
              <% else %>
                <div class="category-item">
                  <span class="category-item__name"><%= cat.name %></span>
                  <div class="category-item__actions">
                    <button class="btn-icon" ignite-click="start_edit_category" ignite-value="<%= cat.id %>">✎</button>
                    <button class="btn-icon btn-icon--danger" ignite-click="delete_category" ignite-value="<%= cat.id %>">✕</button>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
      """
    end
  end

  defp error_tag(errors, field) do
    case Map.get(errors, field) do
      nil -> ""
      msg -> ~s(<p class="form-error">#{Ignite.LiveView.FEExEngine.escape(msg)}</p>)
    end
  end

  defp error_class(errors, field) do
    if Map.has_key?(errors, field), do: "form-input--error", else: ""
  end

  defp status_display("pending"), do: "Pending"
  defp status_display("in_progress"), do: "In Progress"
  defp status_display("completed"), do: "Completed"
  defp status_display(s), do: s

  defp page_range(_current, total) when total <= 7 do
    Enum.to_list(1..total)
  end

  defp page_range(current, total) do
    cond do
      current <= 3 ->
        Enum.to_list(1..4) ++ [:ellipsis, total]
      current >= total - 2 ->
        [1, :ellipsis] ++ Enum.to_list((total - 3)..total)
      true ->
        [1, :ellipsis, current - 1, current, current + 1, :ellipsis, total]
    end
  end
end
