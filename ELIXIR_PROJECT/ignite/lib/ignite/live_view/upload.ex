defmodule Ignite.LiveView.Upload do
  defstruct [
    :name,
    :accept,
    :max_entries,
    :max_file_size,
    :chunk_size,
    :auto_upload,
    entries: [],
    errors: []
  ]

  defmodule Entry do
    defstruct [
      :ref,
      :upload_name,
      :client_name,
      :client_type,
      :client_size,
      :tmp_path,
      progress: 0,
      done?: false,
      valid?: true,
      errors: []
    ]
  end
end

defmodule Ignite.LiveView.UploadHelpers do
  alias Ignite.LiveView.Upload
  alias Ignite.LiveView.Upload.Entry

  def allow_upload(assigns, name, opts \\ []) do
    upload = %Upload{
      name: name,
      accept: Keyword.get(opts, :accept, []),
      max_entries: Keyword.get(opts, :max_entries, 1),
      max_file_size: Keyword.get(opts, :max_file_size, 8_000_000),
      chunk_size: Keyword.get(opts, :chunk_size, 64_000),
      auto_upload: Keyword.get(opts, :auto_upload, false)
    }

    uploads = Map.get(assigns, :__uploads__, %{})
    Map.put(assigns, :__uploads__, Map.put(uploads, name, upload))
  end

  def consume_uploaded_entries(assigns, name, callback) do
    uploads = Map.get(assigns, :__uploads__, %{})

    upload =
      Map.get(uploads, name) ||
        raise ArgumentError, "upload #{inspect(name)} not configured"

    {completed, remaining} = Enum.split_with(upload.entries, & &1.done?)

    {results, kept} =
      Enum.reduce(completed, {[], []}, fn entry, {results_acc, kept_acc} ->
        case callback.(entry) do
          {:ok, value} ->
            if entry.tmp_path, do: File.rm(entry.tmp_path)
            {[value | results_acc], kept_acc}

          {:postpone, _} ->
            {results_acc, [entry | kept_acc]}
        end
      end)

    updated_upload = %{upload | entries: remaining ++ Enum.reverse(kept)}
    updated_uploads = Map.put(uploads, name, updated_upload)
    {Map.put(assigns, :__uploads__, updated_uploads), Enum.reverse(results)}
  end

  def live_file_input(assigns, name) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name) || raise ArgumentError, "upload #{inspect(name)} not configured"

    accept = Enum.join(upload.accept, ",")
    
    # Generate simple HTML input
    """
    <input type="file" 
           ignite-upload="#{upload.name}"
           accept="#{accept}" 
           #{if upload.max_entries > 1, do: "multiple", else: ""}
           data-auto-upload="#{upload.auto_upload}"
           data-chunk-size="#{upload.chunk_size}"
           data-max-file-size="#{upload.max_file_size}"
           data-max-entries="#{upload.max_entries}" />
    """
  end

  # Internal Protocol Handlers (called by LiveView.Handler)

  def validate_entries(assigns, name, entries_params) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name) || raise ArgumentError, "upload #{inspect(name)} not configured"

    new_entries =
      Enum.map(entries_params, fn %{"ref" => ref, "name" => client_name, "type" => type, "size" => size} ->
        # Find existing or create new
        existing = Enum.find(upload.entries, &(&1.ref == ref))
        
        entry = existing || %Entry{
          ref: ref,
          upload_name: name,
          client_name: client_name,
          client_type: type,
          client_size: size
        }

        # Validate
        errors = []
        errors = if size > upload.max_file_size, do: [:too_large | errors], else: errors
        # In a real framework we'd check allowed types here too
        
        %{entry | errors: errors, valid?: errors == []}
      end)

    updated_upload = %{upload | entries: new_entries}
    Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_upload))
  end

  def receive_chunk(assigns, ref, chunk_data) do
    uploads = Map.get(assigns, :__uploads__, %{})
    
    # Find which upload/entry this ref belongs to
    result = 
      Enum.find_value(uploads, fn {name, upload} ->
        case Enum.find(upload.entries, &(&1.ref == ref)) do
          nil -> nil
          entry -> {name, upload, entry}
        end
      end)

    case result do
      nil -> assigns
      {name, upload, entry} ->
        # Ensure temp file
        tmp_path = entry.tmp_path || (
          {:ok, path} = Ignite.Upload.random_file("lv-upload")
          Ignite.Upload.schedule_cleanup(path)
          path
        )

        File.write!(tmp_path, chunk_data, [:append])
        
        # Calculate progress
        new_size = File.stat!(tmp_path).size
        progress = trunc((new_size / entry.client_size) * 100)
        progress = if progress > 100, do: 100, else: progress
        
        new_entry = %{entry | tmp_path: tmp_path, progress: progress}
        new_entries = Enum.map(upload.entries, fn e -> if e.ref == ref, do: new_entry, else: e end)
        
        updated_upload = %{upload | entries: new_entries}
        Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_upload))
    end
  end

  def mark_complete(assigns, name, ref) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name)

    if upload do
      new_entries = Enum.map(upload.entries, fn e -> 
        if e.ref == ref, do: %{e | done?: true, progress: 100}, else: e 
      end)
      updated_upload = %{upload | entries: new_entries}
      Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_upload))
    else
      assigns
    end
  end

  def build_upload_config(assigns, name) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name)

    if upload do
      %{
        "name" => to_string(upload.name),
        "chunk_size" => upload.chunk_size,
        "auto_upload" => upload.auto_upload,
        "entries" => Enum.map(upload.entries, fn e -> 
          %{"ref" => e.ref, "valid" => e.valid?, "errors" => e.errors}
        end)
      }
    else
      nil
    end
  end
end
