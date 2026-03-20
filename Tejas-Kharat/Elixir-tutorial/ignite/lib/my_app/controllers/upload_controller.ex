defmodule MyApp.UploadController do
  import Ignite.Controller

  def upload_form(conn) do
    html(conn, """
    <div style="max-width: 600px; margin: 40px auto; font-family: system-ui;">
      <h1>Part A: HTTP File Upload</h1>
      <p style="color: #666;">This uses traditional multipart/form-data and streams directly to disk.</p>

      <form action="/upload" method="post" enctype="multipart/form-data"
            style="background: #f8f9fa; padding: 24px; border-radius: 12px; border: 1px solid #eee;">
        #{csrf_token_tag(conn)}

        <div style="margin-bottom: 20px;">
          <label style="display: block; margin-bottom: 8px; font-weight: bold;">Select File</label>
          <input type="file" name="file" required style="width: 100%;" />
        </div>

        <div style="margin-bottom: 20px;">
          <label style="display: block; margin-bottom: 8px; font-weight: bold;">Description</label>
          <input type="text" name="description" placeholder="What is this file?"
                 style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box;" />
        </div>

        <button type="submit"
                style="padding: 12px 24px; background: #3498db; color: white; border: none;
                       border-radius: 6px; cursor: pointer; font-weight: bold; width: 100%;">
          Upload File
        </button>
      </form>

      <div style="margin-top: 24px; text-align: center;">
        <a href="/" style="color: #3498db; text-decoration: none;">&larr; Back to Home</a>
      </div>
    </div>
    """)
  end

  def upload(conn) do
    case conn.params["file"] do
      %Ignite.Upload{} = upload ->
        # Create uploads directory if it doesn't exist
        File.mkdir_p!("uploads")

        # Sanitize and generate a unique filename
        safe_name = sanitize_filename(upload.filename)
        dest = Path.join("uploads", safe_name)

        # Copy from temp path to permanent destination
        File.cp!(upload.path, dest)

        size = File.stat!(dest).size
        description = Map.get(conn.params, "description", "No description")

        html(conn, """
        <div style="max-width: 600px; margin: 40px auto; font-family: system-ui; text-align: center;">
          <div style="background: #d4edda; color: #155724; padding: 20px; border-radius: 12px; margin-bottom: 24px;">
            <h2 style="margin-top: 0;">Upload Successful!</h2>
            <p>Your file has been saved to the server.</p>
          </div>

          <div style="text-align: left; background: white; padding: 24px; border: 1px solid #eee; border-radius: 12px;">
            <p><strong>Filename:</strong> #{escape(upload.filename)}</p>
            <p><strong>Saved As:</strong> <code style="background: #f0f0f0; padding: 2px 4px;">#{safe_name}</code></p>
            <p><strong>Size:</strong> #{format_size(size)}</p>
            <p><strong>Content Type:</strong> #{escape(upload.content_type)}</p>
            <p><strong>Description:</strong> #{escape(description)}</p>
          </div>

          <div style="margin-top: 32px; display: flex; gap: 16px; justify-content: center;">
            <a href="/upload" style="color: #3498db; text-decoration: none; font-weight: bold;">Upload Another</a>
            <span style="color: #ccc;">|</span>
            <a href="/" style="color: #3498db; text-decoration: none; font-weight: bold;">Home</a>
          </div>
        </div>
        """)

      _ ->
        conn
        |> html("""
          <h1>Error</h1>
          <p>No file was uploaded or the request was invalid.</p>
          <a href="/upload">Try again</a>
        """, 400)
    end
  end

  defp sanitize_filename(name) do
    timestamp = System.system_time(:millisecond) |> Integer.to_string()
    # Basic sanitization: keep only alphanumeric, dots, and dashes
    safe =
      name
      |> Path.basename()
      |> String.replace(~r/[^\w.\-]/, "_")

    "#{timestamp}-#{safe}"
  end

  defp escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
  defp escape(nil), do: ""

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"
end
