defmodule Ignite.LiveView.Stream do
  @moduledoc """
  Manages a collection of items for efficient O(1) updates in LiveView.
  """

  defstruct [
    :name,       # atom identifier (e.g. :events)
    :render_fn,  # fn(item) -> html_string
    :dom_prefix, # string prefix for DOM IDs
    :id_fn,      # fn(item) -> string (extracts unique ID)
    :limit,      # nil | pos_integer — max items on client
    ops: [],     # queue of pending operations: {:insert, item, options} or {:delete, item}
    items: %{},   # map of current DOM IDs to track presence
    order: []     # list of dom_ids in insertion order (for limit pruning)
  ]

  @doc """
  Initializes a new stream.
  """
  def new(name, opts \\ []) do
    %__MODULE__{
      name: name,
      render_fn: Keyword.fetch!(opts, :render),
      dom_prefix: to_string(name),
      id_fn: opts[:id] || fn %{id: id} -> to_string(id) end,
      limit: opts[:limit],
      ops: [],
      items: %{},
      order: []
    }
  end

  @doc """
  Queues an insert operation.
  """
  def insert(stream, item, opts \\ []) do
    id = stream.id_fn.(item)
    dom_id = "#{stream.dom_prefix}-#{id}"
    position = opts[:at] || -1

    is_update = Map.has_key?(stream.items, dom_id)

    # Maintain the order list (only for new items)
    new_order =
      if is_update do
        stream.order
      else
        if position == 0, do: [dom_id | stream.order], else: stream.order ++ [dom_id]
      end

    # Track presence
    new_items = Map.put(stream.items, dom_id, true)

    # Queue the insert operation
    ops = [{:insert, item, dom_id, opts} | stream.ops]

    # Apply limit if needed
    {final_ops, final_items, final_order} =
      apply_limit(ops, new_items, new_order, stream.limit, position)

    %{stream | ops: final_ops, items: final_items, order: final_order}
  end

  @doc """
  Queues a delete operation.
  """
  def delete(stream, item) do
    id = stream.id_fn.(item)
    dom_id = "#{stream.dom_prefix}-#{id}"

    new_items = Map.delete(stream.items, dom_id)
    new_order = List.delete(stream.order, dom_id)

    %{stream | ops: [{:delete, dom_id} | stream.ops], items: new_items, order: new_order}
  end

  @doc """
  Resets the stream.
  """
  def reset(stream) do
    %{stream | ops: [:reset]}
  end

  @doc """
  Extracts pending operations and renders them to wire format.
  Returns {wire_payload, updated_stream_with_empty_ops}.
  """
  def extract_ops(stream) do
    # Reverse to process in original call order
    ops = Enum.reverse(stream.ops)
    
    payload = 
      Enum.reduce(ops, %{}, fn
        :reset, _acc -> 
          %{reset: true}

        {:delete, dom_id}, acc ->
          deletes = Map.get(acc, :deletes, [])
          Map.put(acc, :deletes, deletes ++ [dom_id])

        {:insert, item, dom_id, opts}, acc ->
          inserts = Map.get(acc, :inserts, [])
          html = stream.render_fn.(item)
          insert_entry = %{
            id: dom_id,
            at: opts[:at], 
            html: html
          }
          Map.put(acc, :inserts, inserts ++ [insert_entry])
      end)

    {payload, %{stream | ops: []}}
  end

  # --- Private Helpers ---

  defp apply_limit(ops, items, order, nil, _at), do: {ops, items, order}

  defp apply_limit(ops, items, order, limit, at) when length(order) > limit do
    excess = length(order) - limit

    # Prune from the opposite end of where inserts happen
    {to_prune, to_keep} =
      if at == 0 do
        # Inserting at front -> prune from end
        {Enum.take(order, -excess), Enum.drop(order, -excess)}
      else
        # Appending -> prune from front
        {Enum.take(order, excess), Enum.drop(order, excess)}
      end

    prune_ops = Enum.map(to_prune, fn dom_id -> {:delete, dom_id} end)

    pruned_items =
      Enum.reduce(to_prune, items, fn dom_id, acc ->
        Map.delete(acc, dom_id)
      end)

    {ops ++ prune_ops, pruned_items, to_keep}
  end

  defp apply_limit(ops, items, order, _limit, _at), do: {ops, items, order}
end
