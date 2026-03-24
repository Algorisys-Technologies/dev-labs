defmodule MyApp.TodoLive do
  use Ignite.LiveView
  import Ecto.Query
  alias MyApp.{Repo, TodoUser, TodoItem, Category, Subtask}

  # ═══════════════════════════════════════════════════════════════════
  # Lifecycle
  # ═══════════════════════════════════════════════════════════════════

  @impl true
  def mount(_params, session) do
    seed_data()

    # Restore user from session cookie if present
    raw_token = Map.get(session, "_csrf_token") || Ignite.CSRF.generate_token()
    base = %{
      current_user: nil,
      csrf_token: Ignite.CSRF.mask_token(raw_token),
      auth_mode: :login,
      auth_errors: %{},
      todos: [],
      total_count: 0,
      new_title: "",
      new_category_id: "",
      editing_id: nil,
      editing_title: "",
      filter: "all",
      search: "",
      show_bookmarked: false,
      category_filter: "",
      page: 1,
      per_page: 10,
      categories: [],
      show_category_mgmt: false,
      new_category_name: "",
      editing_category_id: nil,
      editing_category_name: "",
      selected_ids: MapSet.new(),
      active_todo_id: nil,
      subtasks: [],
      new_subtask_title: "",
      confirm_delete_id: nil
    }

    assigns =
      case Map.get(session, "user_id") do
        nil -> base
        user_id ->
          case Repo.get(TodoUser, user_id) do
            nil -> base
            user ->
              base
              |> Map.put(:current_user, user_map(user))
              |> load_categories()
              |> load_todos()
          end
      end

    {:ok, assigns}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Auth Events (Level 4-5)
  # ═══════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("switch_auth", _params, assigns) do
    new_mode = if assigns.auth_mode == :login, do: :register, else: :login
    {:noreply, %{assigns | auth_mode: new_mode, auth_errors: %{}}}
  end


  # ═══════════════════════════════════════════════════════════════════
  # CRUD Events (Level 0)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("add_todo", params, assigns) do
    title = String.trim(params["title"] || "")

    if title == "" do
      {:noreply, assigns}
    else
      category_id =
        case params["category_id"] do
          v when v in ["", nil] -> nil
          id -> to_int(id)
        end

      attrs = %{title: title, user_id: assigns.current_user.id, category_id: category_id}

      case Repo.insert(TodoItem.changeset(%TodoItem{}, attrs)) do
        {:ok, _} ->
          {:noreply, load_todos(%{assigns | new_title: "", new_category_id: ""})}

        {:error, _} ->
          {:noreply, assigns}
      end
    end
  end

  def handle_event("cycle_status", %{"value" => id_str}, assigns) do
    id = to_int(id_str)
    case Repo.get(TodoItem, id) do
      %TodoItem{user_id: uid} = todo when uid == assigns.current_user.id ->
        Repo.update(TodoItem.changeset(todo, %{status: next_status(todo.status)}))
        {:noreply, load_todos(assigns)}
      _ ->
        {:noreply, assigns}
    end
  end

  def handle_event("start_edit", %{"value" => id_str}, assigns) do
    id = to_int(id_str)
    todo = Enum.find(assigns.todos, &(&1.id == id))

    if todo do
      {:noreply, %{assigns | editing_id: id, editing_title: todo.title}}
    else
      {:noreply, assigns}
    end
  end

  def handle_event("save_edit", params, assigns) do
    title = String.trim(params["title"] || "")

    if assigns.editing_id && title != "" do
      case Repo.get(TodoItem, assigns.editing_id) do
        %TodoItem{user_id: uid} = todo when uid == assigns.current_user.id ->
          Repo.update(TodoItem.changeset(todo, %{title: title}))

        _ ->
          :ok
      end
    end

    {:noreply, load_todos(%{assigns | editing_id: nil, editing_title: ""})}
  end

  def handle_event("cancel_edit", _params, assigns) do
    {:noreply, %{assigns | editing_id: nil, editing_title: ""}}
  end

  def handle_event("confirm_delete", %{"value" => id_str}, assigns) do
    {:noreply, %{assigns | confirm_delete_id: to_int(id_str)}}
  end

  def handle_event("cancel_delete", _params, assigns) do
    {:noreply, %{assigns | confirm_delete_id: nil}}
  end

  def handle_event("delete_todo", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    case Repo.get(TodoItem, id) do
      %TodoItem{user_id: uid} = todo when uid == assigns.current_user.id ->
        Repo.delete(todo)

      _ ->
        :ok
    end

    assigns = %{assigns | confirm_delete_id: nil, selected_ids: MapSet.delete(assigns.selected_ids, id)}

    assigns =
      if assigns.active_todo_id == id,
        do: %{assigns | active_todo_id: nil, subtasks: []},
        else: assigns

    {:noreply, load_todos(assigns)}
  end

  # Selection & Bulk Actions (Level 0)

  def handle_event("toggle_select", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    selected =
      if MapSet.member?(assigns.selected_ids, id),
        do: MapSet.delete(assigns.selected_ids, id),
        else: MapSet.put(assigns.selected_ids, id)

    {:noreply, %{assigns | selected_ids: selected}}
  end

  def handle_event("toggle_select_all", _params, assigns) do
    all_ids = MapSet.new(assigns.todos, & &1.id)

    selected =
      if MapSet.size(assigns.selected_ids) == length(assigns.todos) and length(assigns.todos) > 0,
        do: MapSet.new(),
        else: all_ids

    {:noreply, %{assigns | selected_ids: selected}}
  end

  def handle_event("bulk_action", %{"value" => action}, assigns) do
    ids = MapSet.to_list(assigns.selected_ids)

    if ids != [] do
      uid = assigns.current_user.id

      case action do
        "delete" ->
          from(t in TodoItem, where: t.id in ^ids and t.user_id == ^uid)
          |> Repo.delete_all()

        "mark_completed" ->
          from(t in TodoItem, where: t.id in ^ids and t.user_id == ^uid)
          |> Repo.update_all(set: [status: "completed"])

        "mark_pending" ->
          from(t in TodoItem, where: t.id in ^ids and t.user_id == ^uid)
          |> Repo.update_all(set: [status: "pending"])

        _ ->
          :ok
      end
    end

    {:noreply, load_todos(%{assigns | selected_ids: MapSet.new()})}
  end

  # Filter (Level 0)
  def handle_event("set_filter", %{"value" => filter}, assigns) do
    {:noreply, load_todos(%{assigns | filter: filter, page: 1, selected_ids: MapSet.new()})}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Pagination Events (Level 1)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("set_page", %{"value" => page_str}, assigns) do
    {:noreply, load_todos(%{assigns | page: to_int(page_str), selected_ids: MapSet.new()})}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Search Events (Level 2)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("search", params, assigns) do
    search = String.trim(params["search"] || "")
    {:noreply, load_todos(%{assigns | search: search, page: 1, selected_ids: MapSet.new()})}
  end

  def handle_event("clear_search", _params, assigns) do
    {:noreply, load_todos(%{assigns | search: "", page: 1, selected_ids: MapSet.new()})}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Bookmark Events (Level 3)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("toggle_bookmark", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    case Repo.get(TodoItem, id) do
      %TodoItem{user_id: uid} = todo when uid == assigns.current_user.id ->
        Repo.update(TodoItem.changeset(todo, %{bookmarked: !todo.bookmarked}))

      _ ->
        :ok
    end

    {:noreply, load_todos(assigns)}
  end

  def handle_event("toggle_bookmarked_filter", _params, assigns) do
    {:noreply,
     load_todos(%{assigns | show_bookmarked: !assigns.show_bookmarked, page: 1, selected_ids: MapSet.new()})}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Generic Change Handler
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("change", %{"field" => "per_page", "value" => val}, assigns) do
    {:noreply, load_todos(%{assigns | per_page: to_int(val), page: 1, selected_ids: MapSet.new()})}
  end

  def handle_event("change", %{"field" => "category_filter", "value" => val}, assigns) do
    {:noreply, load_todos(%{assigns | category_filter: val, page: 1, selected_ids: MapSet.new()})}
  end

  def handle_event("change", _params, assigns) do
    {:noreply, assigns}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Category Events (Level 6, 6.1)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("toggle_category_mgmt", _params, assigns) do
    {:noreply, %{assigns | show_category_mgmt: !assigns.show_category_mgmt}}
  end

  def handle_event("add_category", params, assigns) do
    name = String.trim(params["name"] || "")

    if name != "" do
      case Repo.insert(Category.changeset(%Category{}, %{name: name})) do
        {:ok, _} ->
          {:noreply, load_categories(%{assigns | new_category_name: ""})}

        {:error, _} ->
          {:noreply, assigns}
      end
    else
      {:noreply, assigns}
    end
  end

  def handle_event("start_edit_category", %{"value" => id_str}, assigns) do
    id = to_int(id_str)
    cat = Enum.find(assigns.categories, &(&1.id == id))

    if cat do
      {:noreply, %{assigns | editing_category_id: id, editing_category_name: cat.name}}
    else
      {:noreply, assigns}
    end
  end

  def handle_event("save_category", params, assigns) do
    name = String.trim(params["name"] || "")

    if assigns.editing_category_id && name != "" do
      case Repo.get(Category, assigns.editing_category_id) do
        %Category{} = cat -> Repo.update(Category.changeset(cat, %{name: name}))
        _ -> :ok
      end
    end

    assigns = %{assigns | editing_category_id: nil, editing_category_name: ""}
    {:noreply, assigns |> load_categories() |> load_todos()}
  end

  def handle_event("cancel_edit_category", _params, assigns) do
    {:noreply, %{assigns | editing_category_id: nil, editing_category_name: ""}}
  end

  def handle_event("delete_category", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    case Repo.get(Category, id) do
      %Category{} = cat -> Repo.delete(cat)
      _ -> :ok
    end

    assigns = load_categories(assigns)
    assigns = if assigns.category_filter == id_str, do: %{assigns | category_filter: ""}, else: assigns
    {:noreply, load_todos(assigns)}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Subtask Events (Level 7)
  # ═══════════════════════════════════════════════════════════════════

  def handle_event("show_subtasks", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    if assigns.active_todo_id == id do
      {:noreply, %{assigns | active_todo_id: nil, subtasks: [], new_subtask_title: ""}}
    else
      subtasks = from(s in Subtask, where: s.todo_item_id == ^id, order_by: [asc: s.id]) |> Repo.all()
      {:noreply, %{assigns | active_todo_id: id, subtasks: subtasks, new_subtask_title: ""}}
    end
  end

  def handle_event("add_subtask", params, assigns) do
    tid = to_int(params["todo_id"])
    title = String.trim(params["title"] || "")

    if title != "" && tid do
      case Repo.insert(Subtask.changeset(%Subtask{}, %{title: title, todo_item_id: tid})) do
        {:ok, _} ->
          subtasks = reload_subtasks(tid)
          {:noreply, %{assigns | subtasks: subtasks, new_subtask_title: ""}}

        {:error, _} ->
          {:noreply, assigns}
      end
    else
      {:noreply, assigns}
    end
  end

  def handle_event("toggle_subtask", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    case Repo.get(Subtask, id) do
      %Subtask{} = subtask ->
        new_status = if subtask.status == "completed", do: "pending", else: "completed"
        Repo.update(Subtask.changeset(subtask, %{status: new_status}))
        subtasks = reload_subtasks(assigns.active_todo_id)
        assigns = maybe_auto_complete_parent(assigns, subtasks)
        {:noreply, %{assigns | subtasks: subtasks}}

      _ ->
        {:noreply, assigns}
    end
  end

  def handle_event("delete_subtask", %{"value" => id_str}, assigns) do
    id = to_int(id_str)

    case Repo.get(Subtask, id) do
      %Subtask{} = subtask -> Repo.delete(subtask)
      _ -> :ok
    end

    subtasks = reload_subtasks(assigns.active_todo_id)
    {:noreply, %{assigns | subtasks: subtasks}}
  end

  # ═══════════════════════════════════════════════════════════════════
  # Render
  # ═══════════════════════════════════════════════════════════════════

  @impl true
  def render(assigns) do
    ~F"""
    <div id="todo-root">
      <%= if @current_user do %>
        <%= MyApp.TodoHTML.render_app(assigns, status_counts(assigns)) %>
      <% else %>
        <%= MyApp.TodoHTML.render_auth(assigns) %>
      <% end %>
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════
  # Private — Data Loading
  # ═══════════════════════════════════════════════════════════════════

  defp user_map(user), do: %{id: user.id, username: user.username, email: user.email}

  defp load_todos(assigns) do
    uid = assigns.current_user.id

    query =
      from(t in TodoItem,
        where: t.user_id == ^uid,
        preload: [:category, :subtasks]
      )
      |> apply_filter(assigns.filter)
      |> apply_bookmarked(assigns.show_bookmarked)
      |> apply_category(assigns.category_filter)
      |> apply_search(assigns.search)

    total_count = Repo.aggregate(query, :count)
    total_pages = max(1, ceil(total_count / assigns.per_page))
    page = min(assigns.page, total_pages)

    todos =
      query
      |> order_by([t], desc: t.inserted_at)
      |> offset(^((page - 1) * assigns.per_page))
      |> limit(^assigns.per_page)
      |> Repo.all()

    %{assigns | todos: todos, total_count: total_count, page: page}
  end

  defp apply_filter(query, "all"), do: query
  defp apply_filter(query, status), do: where(query, [t], t.status == ^status)

  defp apply_bookmarked(query, false), do: query
  defp apply_bookmarked(query, true), do: where(query, [t], t.bookmarked == true)

  defp apply_category(query, ""), do: query
  defp apply_category(query, nil), do: query

  defp apply_category(query, cat_id) when is_binary(cat_id) do
    where(query, [t], t.category_id == ^String.to_integer(cat_id))
  end

  defp apply_search(query, ""), do: query

  defp apply_search(query, search) do
    where(query, [t], like(t.title, ^"%#{search}%"))
  end

  defp load_categories(assigns) do
    categories = from(c in Category, order_by: [asc: c.name]) |> Repo.all()
    %{assigns | categories: categories}
  end

  defp reload_subtasks(todo_id) do
    from(s in Subtask, where: s.todo_item_id == ^todo_id, order_by: [asc: s.id]) |> Repo.all()
  end

  defp maybe_auto_complete_parent(assigns, subtasks) do
    if subtasks != [] && Enum.all?(subtasks, &(&1.status == "completed")) do
      case Repo.get(TodoItem, assigns.active_todo_id) do
        %TodoItem{status: status} = todo when status != "completed" ->
          Repo.update(TodoItem.changeset(todo, %{status: "completed"}))
          load_todos(assigns)

        _ ->
          assigns
      end
    else
      assigns
    end
  end

  defp next_status("pending"), do: "in_progress"
  defp next_status("in_progress"), do: "completed"
  defp next_status("completed"), do: "pending"

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} -> {to_string(field), Enum.join(messages, ", ")} end)
    |> Map.new()
  end

  defp status_counts(assigns) do
    uid = assigns.current_user.id

    base =
      from(t in TodoItem, where: t.user_id == ^uid)
      |> apply_bookmarked(assigns.show_bookmarked)
      |> apply_category(assigns.category_filter)
      |> apply_search(assigns.search)

    total = Repo.aggregate(base, :count)
    pending = Repo.aggregate(where(base, [t], t.status == "pending"), :count)
    in_progress = Repo.aggregate(where(base, [t], t.status == "in_progress"), :count)
    completed = Repo.aggregate(where(base, [t], t.status == "completed"), :count)

    %{all: total, pending: pending, in_progress: in_progress, completed: completed}
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val) and val != "", do: String.to_integer(val)
  defp to_int(_), do: nil

  # --- Seed helpers ---

  defp seed_data do
    unless Repo.get(TodoUser, 1) do
      %TodoUser{id: 1}
      |> TodoUser.changeset(%{username: "Demo User", email: "demo@ignite.dev", password: "password"})
      |> Repo.insert!()
    end

    if Repo.all(Category) == [] do
      Repo.insert!(%Category{name: "Work", color: "#818cf8"})
      Repo.insert!(%Category{name: "Personal", color: "#34d399"})
      Repo.insert!(%Category{name: "Urgent", color: "#fb7185"})
    end
  end
end
