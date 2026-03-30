defmodule MyApp.UploadDemoLive do
  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    assigns = 
      %{uploaded_files: []}
      |> allow_upload(:photos, 
           accept: [".jpg", ".jpeg", ".png", ".pdf"], 
           max_entries: 3, 
           max_file_size: 5_000_000,
           auto_upload: true
         )

    {:ok, assigns}
  end

  @impl true
  def handle_event("save", _params, assigns) do
    # Consume entries: move from temp to permanent storage (or just record metadata)
    {assigns, results} = consume_uploaded_entries(assigns, :photos, fn entry ->
      # In a real app, you'd move entry.tmp_path to a permanent location
      # Here we just record that it happened
      %{name: entry.client_name, size: entry.client_size, type: entry.client_type}
    end)

    {:noreply, %{assigns | uploaded_files: assigns.uploaded_files ++ results}}
  end

  @impl true
  def render(assigns) do
    uploads = Map.get(assigns, :__uploads__, %{})
    photo_upload = Map.get(uploads, :photos)

    # Pre-render entries list to avoid EEx block issues with our simple engine
    entries_html = Enum.map_join(photo_upload.entries, "\n", fn entry ->
      status_html = if entry.done?, do: "<div style=\"color: #ee0808ff; font-size: 0.8em; margin-top: 5px;\">Ready! ✅</div>", else: ""
      
      """
      <div id="#{entry.ref}" style="background: white; border: 1px solid #eee; padding: 15px; border-radius: 8px; margin-bottom: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
        <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
          <span style="font-weight: 600; font-size: 0.9em;">#{entry.client_name}</span>
          <span style="color: #636e72; font-size: 0.8em;">#{entry.progress}%</span>
        </div>
        
        <div style="height: 8px; background: #eee; border-radius: 4px; overflow: hidden;">
          <div style="height: 100%; width: #{entry.progress}%; background:#2f0000; transition: width 0.2s;"></div>
        </div>
        #{status_html}
      </div>
      """
    end)

    results_html = 
      if length(assigns.uploaded_files) > 0 do
        items = Enum.map_join(assigns.uploaded_files, "\n", fn file ->
          "<li style=\"padding: 10px 0; font-size: 0.9em; color: #000000;\">📄 <strong>#{file.name}</strong> (#{file.size} bytes)</li>"
        end)
        """
        <div style="margin-top: 40px;">
          <h4 style="border-bottom: 1px solid #eee; padding-bottom: 10px;">Uploaded Successfully:</h4>
          <ul style="list-style: none; padding: 0;">#{items}</ul>
        </div>
        """
      else
        ""
      end

    ~L"""
    <div id="upload-demo" style="max-width: 600px; margin: 40px auto; padding: 30px; background: #faf9f6; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); font-family: 'Inter', sans-serif; color: #333;">
      <h2 style="text-align: center; color: 	#570101ff;">LiveView Uploads  </h2>
      
      <!-- Drop Zone & File Input -->
      <div ignite-drop-target="photos" 
           style="border: 3px dashed 	#2f0000; border-radius: 12px; padding: 40px; text-align: center; background: white; transition: 0.3s; margin-bottom: 30px;">
        <div style="font-size: 3em; margin-bottom: 10px;">😶‍🌫️</div>
        <p style="margin: 0; color: #636e72;">Drag and drop files here or click to select</p>
        <div style="margin-top: 20px;">
          <%= live_file_input(assigns, :photos) %>
        </div>
      </div>

      <!-- Upload Progress -->
      <div id="entries" style="margin-bottom: 30px;">
        <%= entries_html %>
      </div>

      <button ignite-click="save" 
              style="width: 100%; background: 	#2f0000; color: white; border: none; padding: 15px; border-radius: 8px; font-weight: 600; cursor: pointer; transition: 0.3s;">
        Save Uploaded Files
      </button>

      <!-- Results List -->
      <%= results_html %>

      <div style="margin-top: 30px; text-align: center; font-size: 0.8em;">
        <a href="/" style="color: 	#2f0000; text-decoration: none;"> Back to Examples</a>
      </div>
    </div>

    <style>
      .drag-over {
        background: #f4e8e9 !important;
        border-color: #5e1921 !important;
        transform: scale(1.02);
      }
      input[type="file"]::file-selector-button {
        background: 	#2f0000;
        color: white;
        border: none;
        padding: 8px 16px;
        border-radius: 4px;
        cursor: pointer;
        margin-right: 15px;
      }
    </style>
    """
  end
end
