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

        {:ok, %{
          name: entry.client_name,
          size: entry.client_size,
          type: entry.client_type,
          url: "/uploads/#{safe_name}"
        }}
      end)

    message = "#{length(results)} file(s) saved successfully!"
    {:noreply, %{assigns | uploaded_files: assigns.uploaded_files ++ results, message: message}}
  end

  @impl true
  def handle_event("clear", _params, assigns) do
    assigns =
      allow_upload(assigns, :photos,
        accept: ["image/*", ".pdf", ".txt", ".md"],
        max_entries: 5,
        max_file_size: 5_000_000,
        auto_upload: true
      )

    {:noreply, %{assigns | uploaded_files: [], message: nil}}
  end

  @impl true
  def render(assigns) do
    uploads_config = Map.get(assigns, :__uploads__, %{})
    photo_upload = Map.get(uploads_config, :photos)

    entries_html =
      photo_upload.entries
      |> Enum.map(fn entry ->
        bar_color = if entry.done?, do: "#2ecc71", else: "#3498db"
        status = if entry.done?, do: "Ready", else: "#{entry.progress}%"

        """
        <div style="display: flex; align-items: center; gap: 16px; padding: 12px;
                    background: #f8f9fa; border-radius: 8px; margin: 8px 0; border: 1px solid #eee;">
          <div style="flex: 1;">
            <div style="font-weight: bold; font-size: 14px;">#{escape(entry.client_name)}</div>
            <div style="font-size: 12px; color: #888;">#{format_size(entry.client_size)} &middot; #{entry.client_type}</div>
          </div>
          <div style="width: 120px;">
            <div style="height: 8px; background: #eee; border-radius: 4px; overflow: hidden; margin-bottom: 4px;">
              <div style="width: #{entry.progress}%; height: 100%; background: #{bar_color}; transition: width 0.3s;"></div>
            </div>
            <div style="text-align: right; font-size: 10px; font-weight: bold; color: #{bar_color};">#{status}</div>
          </div>
        </div>
        """
      end)
      |> Enum.join("")

    all_done = photo_upload.entries != [] && Enum.all?(photo_upload.entries, & &1.done?)
    save_disabled = if all_done, do: "", else: " disabled"

    message_html =
      if assigns.message do
        """
        <div style="background: #d4edda; color: #155724; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
          #{escape(assigns.message)}
        </div>
        """
      else
        ""
      end

    recent_files_html =
      if assigns.uploaded_files != [] do
        items =
          assigns.uploaded_files
          |> Enum.map(fn file ->
            """
            <li style="padding: 8px 0; border-bottom: 1px solid #eee; display: flex; justify-content: space-between;">
              <span>#{escape(file.name)}</span>
              <span style="color: #888; font-size: 12px;">#{format_size(file.size)}</span>
            </li>
            """
          end)
          |> Enum.join("")

        """
        <div style="margin-top: 40px;">
          <h3>Recently Uploaded</h3>
          <ul style="list-style: none; padding: 0;">
            #{items}
          </ul>
        </div>
        """
      else
        ""
      end

    ~L"""
    <div style="max-width: 600px; margin: 40px auto; font-family: system-ui;">
      <h1>Part B: LiveView File Uploads</h1>
      <p style="color: #666;">Chunked binary upload over WebSockets with real-time progress.</p>

      <%= message_html %>

      <form ignite-submit="save">
        <div ignite-drop-target="photos"
             style="border: 2px dashed #3498db; border-radius: 12px; padding: 40px;
                    text-align: center; background: #ebf5fb; transition: all 0.3s;"
             class="ignite-drop-zone">
          <p style="margin: 0; color: #3498db; font-weight: bold;">
            Drag & Drop photos here
          </p>
          <p style="margin: 8px 0 20px 0; font-size: 14px; color: #888;">or click to browse</p>

          <div style="display: inline-block;">
            <%= live_file_input(assigns, :photos) %>
          </div>
        </div>

        <div style="margin: 20px 0;">
          <%= entries_html %>
        </div>

        <div style="display: flex; gap: 12px;">
          <button type="submit"<%= save_disabled %>
                  style="flex: 1; padding: 12px; background: #3498db; color: white;
                         border: none; border-radius: 8px; cursor: pointer; font-weight: bold;">
            Save Files
          </button>

          <button type="button" ignite-click="clear"
                  style="padding: 12px 24px; background: white; color: #e74c3c;
                         border: 1px solid #e74c3c; border-radius: 8px; cursor: pointer;">
            Clear All
          </button>
        </div>
      </form>

      <%= recent_files_html %>

      <div style="margin-top: 40px; text-align: center; border-top: 1px solid #eee; padding-top: 20px;">
        <a href="/" style="color: #3498db; text-decoration: none;">&larr; Back to Home</a>
      </div>

      <style>
        .ignite-drag-over {
          background: #d6eaf8 !important;
          border-color: #2980b9 !important;
          transform: scale(1.02);
        }
        button:disabled {
          background: #ccc !important;
          cursor: not-allowed !important;
        }
      </style>
    </div>
    """
  end

  defp sanitize_filename(name) do
    timestamp = System.system_time(:millisecond) |> Integer.to_string()
    safe = name |> Path.basename() |> String.replace(~r/[^\w.\-]/, "_")
    "#{timestamp}-#{safe}"
  end

  defp escape(text) when is_binary(text) do
    text |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
  end
  defp escape(nil), do: ""

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"
end
