defmodule MyApp.SubtaskComponent do
  @moduledoc """
  A LiveComponent that manages subtasks for a todo item.
  Demonstrates Ignite's LiveComponent feature (Step 24) —
  self-contained state management and event handling.
  """
  use Ignite.LiveComponent

  alias MyApp.{Repo, Subtask}
  import Ecto.Query

  def mount(props) do
    todo_id = props.todo_id
    subtasks = Repo.all(from s in Subtask, where: s.todo_item_id == ^todo_id, order_by: [asc: s.inserted_at])
    {:ok, Map.merge(props, %{subtasks: subtasks, expanded: true})}
  end

  def handle_event("add-subtask", %{"title" => title}, assigns) when title != "" do
    {:ok, subtask} = Repo.insert(Subtask.changeset(%Subtask{}, %{title: title, todo_item_id: assigns.todo_id}))
    {:noreply, %{assigns | subtasks: assigns.subtasks ++ [subtask]}}
  end

  def handle_event("add-subtask", _params, assigns), do: {:noreply, assigns}

  def handle_event("toggle-subtask", %{"value" => id}, assigns) do
    id_int = String.to_integer(id)
    subtask = Repo.get!(Subtask, id_int)
    {:ok, updated} = Repo.update(Subtask.changeset(subtask, %{completed: !subtask.completed}))
    subtasks = Enum.map(assigns.subtasks, fn s -> if s.id == updated.id, do: updated, else: s end)
    {:noreply, %{assigns | subtasks: subtasks}}
  end

  def render(assigns) do
    done_count = Enum.count(assigns.subtasks, & &1.completed)
    total = length(assigns.subtasks)
    progress = if total > 0, do: round(done_count / total * 100), else: 0

    subtask_rows = assigns.subtasks |> Enum.map(&render_subtask/1) |> Enum.join("")

    """
    <div class="subtask-panel">
      <div class="subtask-header">
        <span class="subtask-title">📋 Subtasks</span>
        <span class="subtask-progress">#{done_count}/#{total}</span>
      </div>

      #{if total > 0 do
        """
        <div class="progress-bar">
          <div class="progress-fill" style="width: #{progress}%"></div>
        </div>
        """
      else
        ""
      end}

      <div class="subtask-list">
        #{subtask_rows}
      </div>

      <form ignite-submit="#{assigns.id}:add-subtask" class="subtask-form">
        <input name="title" placeholder="Add subtask..." autocomplete="off" />
        <button type="submit">+</button>
      </form>
    </div>
    """
  end

  defp render_subtask(subtask) do
    checked = if subtask.completed, do: "checked", else: ""
    deco = if subtask.completed, do: "line-through", else: "none"
    opacity = if subtask.completed, do: "0.5", else: "1"

    """
    <div class="subtask-item" style="opacity: #{opacity};">
      <input type="checkbox" #{checked}
             ignite-click="toggle-subtask" ignite-value="#{subtask.id}" />
      <span style="text-decoration: #{deco};">#{escape(subtask.title)}</span>
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
