defmodule Ignite.LiveView do
  @doc "Called when the LiveView process starts. Returns initial assigns."
  @callback mount(params :: map(), session :: map()) :: {:ok, map()}

  @doc "Called when the browser sends an event (click, form submit, etc.)."
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) ::
              {:noreply, map()}

  @doc "Called for background messages (PubSub, timers, etc.)."
  @callback handle_info(msg :: term(), assigns :: map()) :: {:noreply, map()}

  @doc "Returns the HTML string for the current assigns."
  @callback render(assigns :: map()) :: String.t()

  @optional_callbacks [handle_info: 2]

  defmacro __using__(_opts) do
    quote do
      @behaviour Ignite.LiveView
      import Ignite.LiveView,
        only: [push_redirect: 2, live_component: 3, sigil_L: 2, sigil_F: 2, raw: 1]

      import Ignite.LiveView.UploadHelpers

      import Ignite.LiveView.Stream,
        only: [
          stream: 3,
          stream: 4,
          stream_insert: 3,
          stream_insert: 4,
          stream_delete: 3
        ]
    end
  end

  defmacro sigil_L({:<<>>, _meta, [template]}, _modifiers) do
    EEx.compile_string(template, engine: Ignite.LiveView.EExEngine)
  end

  @doc """
  Flame EEx sigil (~F).
  Supports @name shorthand and auto-escaping via Ignite.LiveView.FEExEngine.
  """
  defmacro sigil_F({:<<>>, _meta, [template]}, _modifiers) do
    processed = Regex.replace(~r/(?<![.\w:\/])@(\w+)/, template, "assigns.\\1")
    EEx.compile_string(processed, engine: Ignite.LiveView.FEExEngine)
  end

  @doc """
  Marks a string as "safe" to skip HTML escaping.
  """
  def raw(val), do: {:safe, val}

  @doc """
  Triggers a client-side redirect to the given URL.
  """
  def push_redirect(assigns, url) do
    Map.put(assigns, :__redirect__, %{url: url})
  end

  @doc """
  Renders a stateful component.
  """
  def live_component(parent_assigns, module, opts) do
    id = Keyword.fetch!(opts, :id)
    props = opts |> Keyword.delete(:id) |> Map.new()

    # Look up existing component state
    components = Map.get(parent_assigns, :__components__, %{})

    comp_assigns =
      case Map.get(components, id) do
        {^module, existing_assigns} ->
          # Existing — merge new props from parent
          Map.merge(existing_assigns, props)

        _ ->
          # New — call mount if defined
          if function_exported?(module, :mount, 1) do
            {:ok, initial} = module.mount(props)
            initial
          else
            props
          end
      end

    # Store in process dictionary (side-channel during render)
    rendered = Process.get(:__ignite_components__, %{})
    Process.put(:__ignite_components__, Map.put(rendered, id, {module, comp_assigns}))

    # Render with wrapper div
    html = module.render(comp_assigns)
    ~s(<div ignite-component="#{id}">#{html}</div>)
  end

  @doc """
  Collects rendered components from the process dictionary and merges them into assigns.
  """
  def collect_components(assigns) do
    case Process.delete(:__ignite_components__) do
      nil ->
        assigns

      components when map_size(components) == 0 ->
        assigns

      components ->
        Map.put(assigns, :__components__, components)
    end
  end
end
