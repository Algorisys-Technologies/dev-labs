defmodule MyApp.UploadDemoLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    assigns = %{uploaded_files: [], message: nil}

    assigns =
      allow_upload(assigns, :photos,
        accept: ["image/*", ".pdf", ".txt", ".md"],
        max_entries: 5,
        max_file_size: 5_000_000,
        auto_upload: true
      )

    {:ok, assigns}
  end

  @impl true
  def handle_event("validate", _params, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_event("save", _params, assigns) do
    File.mkdir_p!("uploads")

    {assigns, results} =
      consume_uploaded_entries(assigns, :photos, fn entry ->
        safe_name = sanitize_filename(entry.client_name)
        dest = Path.join("uploads", safe_name)
        File.cp!(entry.tmp_path, dest)

        {:ok, %{name: entry.client_name, size: entry.client_size,
                 type: entry.client_type, url: "/uploads/#{safe_name}"}}
      end)

    message = "#{length(results)} file(s) uploaded successfully!"
    {:noreply, %{assigns | uploaded_files: assigns.uploaded_files ++ results, message: message}}
  end

  @impl true
  def handle_event("clear", _params, assigns) do
    assigns =
      allow_upload(assigns, :photos,
        accept: ["image/*", ".pdf", ".txt", ".md"],
        max_entries: 5, max_file_size: 5_000_000, auto_upload: true
      )

    {:noreply, %{assigns | uploaded_files: [], message: nil}}
  end

  @impl true
  def render(assigns) do
    uploads = Map.get(assigns, :__uploads__, %{})
    photo_upload = Map.get(uploads, :photos, %{entries: [], errors: []})

    entries_html =
      photo_upload.entries
      |> Enum.map(fn entry ->
        bar_color = if entry.done?, do: "#27ae60", else: "#3498db"
        status = if entry.done?, do: "Done", else: "#{entry.progress}%"

        """
        <div style="display:flex;align-items:center;gap:12px;padding:8px;
                    background:#f8f9fa;border-radius:6px;margin:4px 0;">
          <span style="flex:1;">#{escape(entry.client_name)}</span>
          <span style="color:#888;font-size:12px;">#{format_size(entry.client_size)}</span>
          <div style="width:100px;height:8px;background:#eee;border-radius:4px;overflow:hidden;">
            <div style="width:#{entry.progress}%;height:100%;background:#{bar_color};
                        transition:width 0.3s;"></div>
          </div>
          <span style="font-size:12px;min-width:40px;">#{status}</span>
        </div>
        """
      end)
      |> Enum.join("")

    all_done = Enum.all?(photo_upload.entries, & &1.done?)
    has_entries = photo_upload.entries != []
    
    # Simple attribute handling since we don't have a sophisticated HTML helper yet
    save_attr = if has_entries and all_done, do: "", else: " disabled"

    message_html = 
      if assigns.message do
        "<div style=\"padding:12px; background:#d4edda; color:#155724; border-radius:4px; margin-bottom:20px;\">#{escape(assigns.message)}</div>"
      else
        ""
      end

    files_html =
      assigns.uploaded_files
      |> Enum.map(fn file ->
        "<li><a href=\"#{file.url}\" target=\"_blank\">#{escape(file.name)}</a> (#{format_size(file.size)})</li>"
      end)
      |> Enum.join("")

    ~L"""
    <div style="max-width:600px;margin:0 auto; font-family: sans-serif; padding: 20px;">
      <h1>LiveView Upload Demo</h1>
      
      <%= message_html %>

      <form ignite-submit="save">
        <div ignite-drop-target="photos"
             style="border:2px dashed #ccc;border-radius:8px;padding:40px;text-align:center; background:#fafafa; transition: border-color 0.2s;">
          <p>Drag &amp; drop files here, or click to select</p>
          <div style="margin: 20px 0;">
            <%= live_file_input(assigns, :photos) %>
          </div>
        </div>
        
        <div style="margin:20px 0;">
          <%= entries_html %>
        </div>

        <div style="display:flex;gap:10px;">
          <button type="submit" <%= save_attr %> 
                  style="padding:10px 20px;background:#27ae60;color:white;border:none;border-radius:4px;cursor:pointer;">
            Save Files
          </button>
          <button type="button" ignite-click="clear"
                  style="padding:10px 20px;background:#95a5a6;color:white;border:none;border-radius:4px;cursor:pointer;">
            Clear
          </button>
        </div>
      </form>

      <div style="margin-top:40px;">
        <h3>Uploaded Files History</h3>
        <ul>
          <%= files_html %>
        </ul>
      </div>

      <p style="margin-top:20px;">
        <a href="/" ignite-navigate="/" style="color:#3498db;">&larr; Back to Home</a>
      </p>
    </div>
    <style>
      .ignite-dragover { border-color: #3498db !important; background: #ebf5fb !important; }
      button:disabled { background: #ccc !important; cursor: not-allowed !important; }
    </style>
    """
  end

  defp escape(text) when is_binary(text) do
    text |> String.replace("&", "&amp;") |> String.replace("<", "&lt;")
        |> String.replace(">", "&gt;")
  end

  defp escape(nil), do: ""

  defp sanitize_filename(name) do
    timestamp = System.system_time(:millisecond) |> Integer.to_string()
    safe = name |> Path.basename() |> String.replace(~r/[^\w.\-]/, "_")
    "#{timestamp}-#{safe}"
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"
end
