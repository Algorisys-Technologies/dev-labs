defmodule MyApp.UploadController do
  import Ignite.Controller

  def upload_form(conn) do
    html(conn, """
    <h1>File Upload</h1>
    <form action="/upload" method="post" enctype="multipart/form-data"
          style="max-width:500px;margin:20px auto;text-align:left;">
      #{csrf_token_tag(conn)}
      <div style="margin-bottom:15px;">
        <label style="display:block;margin-bottom:4px;font-weight:bold;">Select a file</label>
        <input type="file" name="file" required />
      </div>
      <div style="margin-bottom:15px;">
        <label style="display:block;margin-bottom:4px;font-weight:bold;">Description</label>
        <input type="text" name="description" placeholder="Optional description"
               style="width:100%;padding:8px;box-sizing:border-box;" />
      </div>
      <button type="submit" style="padding:10px 20px;background:#3498db;color:white;
              border:none;border-radius:4px;cursor:pointer;">Upload</button>
    </form>
    """)
  end

  def upload(conn) do
    case conn.params["file"] do
      %Ignite.Upload{} = upload ->
        size = File.stat!(upload.path).size
        File.mkdir_p!("uploads")
        safe_name = sanitize_filename(upload.filename)
        dest = Path.join("uploads", safe_name)
        File.cp!(upload.path, dest)

        html(conn, """
        <h1>Upload Successful</h1>
        <p><strong>#{escape(upload.filename)}</strong> — #{size} bytes
           (#{escape(upload.content_type)})</p>
        <p><a href="/upload">Upload another</a> &middot; <a href="/">Home</a></p>
        """)

      _ ->
        text(conn, "No file uploaded", 400)
    end
  end

  defp escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape(nil), do: ""

  defp sanitize_filename(name) do
    timestamp = System.system_time(:millisecond) |> Integer.to_string()
    safe = name |> Path.basename() |> String.replace(~r/[^\w.\-]/, "_")
    "#{timestamp}-#{safe}"
  end
end
