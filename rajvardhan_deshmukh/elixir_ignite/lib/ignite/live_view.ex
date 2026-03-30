defmodule Ignite.LiveView do
  @moduledoc """
  Defines the LiveView behaviour for real-time server-rendered views.

  A LiveView is a stateful process that:
  1. Mounts with initial state
  2. Renders HTML based on that state
  3. Handles events from the browser (clicks, form submissions)
  4. Re-renders and pushes updates over WebSocket
  """

  @doc "Called when the LiveView process starts. Returns initial assigns."
  @callback mount(params :: map(), session :: map()) :: {:ok, map()}

  @doc "Called when the browser sends an event (click, form submit, etc.)."
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) ::
              {:noreply, map()}

  @doc "Returns the HTML string for the current assigns."
  @callback render(assigns :: map()) :: String.t()

  @doc "Handles Erlang messages sent to the LiveView process (e.g. PubSub, timers)."
  @callback handle_info(msg :: term(), assigns :: map()) :: {:noreply, map()}

  @optional_callbacks [handle_info: 2]

  @doc """
  Instructs the client to navigate to a new URL without a full page reload.

  This attaches a special `__redirect__` key to the assigns, which the
  WebSocket handler intercepts and translates into a JSON redirect instruction
  for the frontend.
  """
  def push_redirect(assigns, url) do
    Map.put(assigns, :__redirect__, %{url: url})
  end

  @doc "Initializes or resets a stream in the assigns."
  def stream(assigns, name, items, opts \\ []) do
    streams = Map.get(assigns, :__streams__, %{})
    
    # Initialize the stream struct
    stream = 
      case Map.get(streams, name) do
        nil -> Ignite.LiveView.Stream.new(name, opts)
        existing -> if opts[:reset], do: Ignite.LiveView.Stream.reset(existing), else: existing
      end

    # Bulk insert initial items
    stream = Enum.reduce(items, stream, fn item, acc -> 
      Ignite.LiveView.Stream.insert(acc, item)
    end)

    Map.put(assigns, :__streams__, Map.put(streams, name, stream))
  end

  @doc "Inserts an item into an existing stream."
  def stream_insert(assigns, name, item, opts \\ []) do
    streams = Map.get(assigns, :__streams__, %{})
    stream = Map.fetch!(streams, name)
    updated_stream = Ignite.LiveView.Stream.insert(stream, item, opts)
    Map.put(assigns, :__streams__, Map.put(streams, name, updated_stream))
  end

  @doc "Removes an item from an existing stream."
  def stream_delete(assigns, name, item) do
    streams = Map.get(assigns, :__streams__, %{})
    stream = Map.fetch!(streams, name)
    updated_stream = Ignite.LiveView.Stream.delete(stream, item)
    Map.put(assigns, :__streams__, Map.put(streams, name, updated_stream))
  end

  defmacro __using__(_opts) do
    quote do
      import Ignite.LiveView, only: [
        push_redirect: 2, 
        live_component: 3, 
        sigil_L: 2,
        stream: 3,
        stream: 4,
        stream_insert: 3,
        stream_insert: 4,
        stream_delete: 3,
        allow_upload: 3,
        consume_uploaded_entries: 3,
        live_file_input: 2,
        sigil_F: 2,
        raw: 1
      ]
      @behaviour Ignite.LiveView
    end
  end

  @doc """
  Sigil for LiveView templates.
  Compiles EEx strings into %Rendered{} structs at compile time.
  """
  defmacro sigil_L({:<<>>, _meta, [template]}, _modifiers) do
    EEx.compile_string(template, engine: Ignite.LiveView.EExEngine)
  end

  @doc """
  Sigil for FEEx Templates (~F).
  Supports `@` shorthand, blocks, and auto-escaping.
  """
  defmacro sigil_F({:<<>>, _meta, [template]}, _modifiers) do
    processed = Regex.replace(~r/(?<![.\w:\/])@(\w+)/, template, "assigns.\\1")
    EEx.compile_string(processed, engine: Ignite.LiveView.FEExEngine)
  end

  @doc "Marks HTML as safe so it is not auto-escaped."
  def raw(val), do: {:safe, val}

  @doc """
  Renders a stateful LiveComponent.

  - parent_assigns: The current assigns of the parent LiveView
  - module: The LiveComponent module to render
  - opts: Must include an `:id`. Other keys are passed as props.
  """
  def live_component(parent_assigns, module, opts) do
    id = Keyword.fetch!(opts, :id)
    props = opts |> Keyword.delete(:id) |> Map.new()

    # Look up existing component state in the parent assigns
    components = Map.get(parent_assigns, :__components__, %{})

    comp_assigns =
      case Map.get(components, id) do
        {^module, existing_assigns} ->
          # Existing component: merge new props from parent into old state
          Map.merge(existing_assigns, props)

        _ ->
          # New component: ensure module is loaded and call mount/1 if defined
          _ = Code.ensure_loaded(module)

          if function_exported?(module, :mount, 1) do
            {:ok, initial} = apply(module, :mount, [props])
            initial
          else
            props
          end
      end

    # Store component state in the process dictionary (the "side-channel")
    # This allows us to "collect" any newly mounted or updated components 
    # after the render function is finished, even though render is pure.
    rendered = Process.get(:__ignite_components__, %{})
    Process.put(:__ignite_components__, Map.put(rendered, id, {module, comp_assigns}))

    # Render the component wrapped in a div with its ID for the JS layer
    html = apply(module, :render, [comp_assigns])
    ~s(<div ignite-component="#{id}">#{html}</div>)
  end

  @doc """
  Picks up component states from the process dictionary and saves them 
  back into the main assigns map. Called by the handler after every render.
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

  # --- Upload Support ---

  defmodule Upload do
    defstruct [:name, :accept, :max_entries, :max_file_size, :chunk_size, :auto_upload, entries: [], errors: []]
  end

  defmodule UploadEntry do
    defstruct [:ref, :client_name, :client_type, :client_size, :tmp_path, progress: 0, done?: false, valid?: true, errors: []]
  end

  def allow_upload(assigns, name, opts) do
    config = %Upload{
      name: name,
      accept: Keyword.get(opts, :accept, []),
      max_entries: Keyword.get(opts, :max_entries, 1),
      max_file_size: Keyword.get(opts, :max_file_size, 10_000_000),
      chunk_size: Keyword.get(opts, :chunk_size, 64_000),
      auto_upload: Keyword.get(opts, :auto_upload, false)
    }

    uploads = Map.get(assigns, :__uploads__, %{})
    Map.put(assigns, :__uploads__, Map.put(uploads, name, config))
  end

  def consume_uploaded_entries(assigns, name, func) do
    uploads = Map.get(assigns, :__uploads__, %{})
    config = Map.fetch!(uploads, name)
    
    {completed, ongoing} = Enum.split_with(config.entries, & &1.done?)
    
    results = Enum.map(completed, fn entry ->
      result = func.(entry)
      # Auto-cleanup the temp file after consumption
      File.rm(entry.tmp_path)
      result
    end)

    # Return updated assigns and results
    updated_config = %{config | entries: ongoing}
    {Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_config)), results}
  end

  def live_file_input(assigns, name) do
    uploads = Map.get(assigns, :__uploads__, %{})
    config = Map.fetch!(uploads, name)
    
    accept = Enum.join(config.accept, ",")
    
    ~s(<input type="file" ignite-upload="#{name}" 
        accept="#{accept}" 
        #{if config.max_entries > 1, do: "multiple", else: ""}
        data-auto-upload="#{config.auto_upload}"
        data-chunk-size="#{config.chunk_size}"
        data-max-file-size="#{config.max_file_size}"
        data-max-entries="#{config.max_entries}" />)
  end
end
