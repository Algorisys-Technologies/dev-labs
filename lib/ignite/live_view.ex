defmodule Ignite.LiveView do
  @callback mount(params :: map(), session :: map()) :: {:ok, map()}
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) :: {:noreply, map()}
  @callback handle_info(message :: any(), assigns :: map()) :: {:noreply, map()}
  @callback render(assigns :: map()) :: String.t()

  defmacro __using__(_opts) do
    quote do
      import Ignite.LiveView, only: [
        push_redirect: 2,
        live_component: 3,
        collect_components: 1,
        sigil_L: 2,
        sigil_F: 2,
        raw: 1,
        subscribe: 1,
        broadcast: 2
      ]
      import Ignite.LiveView.UploadHelpers, only: [
        allow_upload: 3,
        consume_uploaded_entries: 3,
        live_file_input: 2
      ]
      import Ignite.LiveView.Stream, only: [
        stream: 3,
        stream: 4,
        stream_insert: 3,
        stream_insert: 4,
        stream_delete: 3
      ]
      @behaviour Ignite.LiveView

      # Define connected?/1 in the using module if needed, 
      # but importing Ignite.LiveView should be enough.
      def connected?(_pid), do: Ignite.LiveView.connected?(self())

      # Default implementations
      def mount(params, session, assigns), do: {:ok, assigns}
      def handle_event(event, params, assigns), do: {:noreply, assigns}
      def handle_info(message, assigns), do: {:noreply, assigns}

      defoverridable mount: 3, handle_event: 3, handle_info: 2
    end
  end

  def connected?(_pid) do
    case Process.get(:ignite_connected) do
      true -> true
      _ -> false
    end
  end

  def subscribe(topic), do: Ignite.PubSub.subscribe(topic)
  def broadcast(topic, message), do: Ignite.PubSub.broadcast(topic, message)

  def push_redirect(assigns, url) do
    Map.put(assigns, :__redirect__, %{url: url})
  end

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

    # Render the component
    rendered = module.render(comp_assigns)
    
    # Use Static.render logic to convert to HTML string
    html = 
      case rendered do
        %Ignite.LiveView.Rendered{} -> 
          statics = rendered.statics
          dynamics = rendered.dynamics
          interleave_html(statics, dynamics)
        other -> to_string(other)
      end

    "<div ignite-component=\"#{id}\">#{html}</div>"
  end

  defp interleave_html([s | statics], [d | dynamics]) do
    s <> to_string(d) <> interleave_html(statics, dynamics)
  end
  defp interleave_html([s], []), do: s
  defp interleave_html([], []), do: ""

  def collect_components(assigns) do
    case Process.delete(:__ignite_components__) do
      nil -> assigns
      components when map_size(components) == 0 -> assigns
      components -> Map.put(assigns, :__components__, components)
    end
  end

  defmacro sigil_L({:<<>>, _meta, [template]}, _modifiers) do
    EEx.compile_string(template, engine: Ignite.LiveView.EExEngine)
  end

  defmacro sigil_F({:<<>>, _meta, [template]}, _modifiers) do
    # Shorthand: @name -> assigns.name
    processed = Regex.replace(~r/(?<![.\w:\/])@(\w+)/, template, "assigns.\\1")
    EEx.compile_string(processed, engine: Ignite.LiveView.FEExEngine)
  end

  def raw(val), do: {:safe, val}
end
