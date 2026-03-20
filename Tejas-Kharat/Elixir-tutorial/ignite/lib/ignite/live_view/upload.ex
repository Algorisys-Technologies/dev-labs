defmodule Ignite.LiveView.Upload do
  defmodule Config do
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
  end

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
  import Ignite.LiveView, only: [sigil_L: 2]
  alias Ignite.LiveView.Upload.Config, as: Upload
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

  def live_file_input(assigns, name) do
    uploads = Map.get(assigns, :__uploads__, %{})

    case Map.get(uploads, name) do
      nil ->
        raise ArgumentError, "no upload configured for name #{inspect(name)}"

      upload ->
        accept = Enum.join(upload.accept, ",")

        ~L"""
        <input type="file"
               ignite-upload="<%= upload.name %>"
               accept="<%= accept %>"
               data-max-entries="<%= upload.max_entries %>"
               data-max-file-size="<%= upload.max_file_size %>"
               data-chunk-size="<%= upload.chunk_size %>"
               data-auto-upload="<%= upload.auto_upload %>"
               <%= if upload.max_entries > 1, do: "multiple" %> />
        """
        |> render_to_html()
    end
  end

  defp render_to_html(rendered) do
    Enum.zip(rendered.statics, rendered.dynamics ++ [""])
    |> Enum.map(fn {s, d} -> s <> to_string(d) end)
    |> Enum.join()
  end

  def validate_entries(assigns, name, entries_params) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name)

    new_entries =
      Enum.map(entries_params, fn p ->
        ref = Map.get(p, "ref")

        # Keep existing entry if it's already there
        existing = Enum.find(upload.entries, &(&1.ref == ref))

        if existing do
          existing
        else
          %Entry{
            ref: ref,
            upload_name: name,
            client_name: Map.get(p, "name"),
            client_type: Map.get(p, "type"),
            client_size: Map.get(p, "size")
          }
          |> validate_entry(upload)
        end
      end)

    updated_upload = %{upload | entries: new_entries}
    updated_uploads = Map.put(uploads, name, updated_upload)
    Map.put(assigns, :__uploads__, updated_uploads)
  end

  defp validate_entry(entry, upload) do
    errors = []

    errors =
      if entry.client_size > upload.max_file_size,
        do: [:file_too_large | errors],
        else: errors

    # (Add more validations here if needed, like MIME type checks)

    %{entry | valid?: errors == [], errors: errors}
  end

  def receive_chunk(assigns, ref, chunk_data) do
    uploads = Map.get(assigns, :__uploads__, %{})

    # Find which upload/entry this chunk belongs to by searching all configs
    # In a real framework, the client would send the upload name too.
    # Here we search for the ref.
    result =
      Enum.find_value(uploads, fn {name, upload} ->
        case Enum.find(upload.entries, &(&1.ref == ref)) do
          nil -> nil
          entry -> {name, upload, entry}
        end
      end)

    case result do
      nil ->
        assigns

      {name, upload, entry} ->
        # 1. Ensure temp file exists
        {:ok, tmp_path} =
          if entry.tmp_path do
            {:ok, entry.tmp_path}
          else
            Ignite.Upload.random_file("lv-upload")
          end

        # Schedule cleanup if it's new
        if is_nil(entry.tmp_path), do: Ignite.Upload.schedule_cleanup(tmp_path)

        # 2. Append chunk to file
        File.write!(tmp_path, chunk_data, [:append])

        # 3. Update progress
        current_size = File.stat!(tmp_path).size
        progress = round(current_size / entry.client_size * 100)

        updated_entry = %{entry | tmp_path: tmp_path, progress: min(progress, 100)}
        updated_entries = Enum.map(upload.entries, fn
          e when e.ref == ref -> updated_entry
          e -> e
        end)

        updated_upload = %{upload | entries: updated_entries}
        Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_upload))
    end
  end

  def mark_complete(assigns, name, ref) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name)

    updated_entries = Enum.map(upload.entries, fn
      e when e.ref == ref -> %{e | done?: true, progress: 100}
      e -> e
    end)

    updated_upload = %{upload | entries: updated_entries}
    Map.put(assigns, :__uploads__, Map.put(uploads, name, updated_upload))
  end

  def consume_uploaded_entries(assigns, name, callback) do
    uploads = Map.get(assigns, :__uploads__, %{})
    upload = Map.get(uploads, name)

    {completed, remaining} = Enum.split_with(upload.entries, & &1.done?)

    results =
      Enum.map(completed, fn entry ->
        case callback.(entry) do
          {:ok, value} -> value
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    # After consumption, we effectively "clear" these entries
    updated_upload = %{upload | entries: remaining}
    updated_uploads = Map.put(uploads, name, updated_upload)
    {Map.put(assigns, :__uploads__, updated_uploads), results}
  end

  def build_upload_config(assigns, name) do
    uploads = Map.get(assigns, :__uploads__, %{})

    case Map.get(uploads, name) do
      nil ->
        nil

      upload ->
        %{
          name: to_string(name),
          chunk_size: upload.chunk_size,
          auto_upload: upload.auto_upload,
          entries:
            Enum.map(upload.entries, fn e ->
              %{ref: e.ref, valid: e.valid?, errors: e.errors}
            end)
        }
    end
  end
end
