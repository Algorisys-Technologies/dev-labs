defmodule Ignite.Adapters.Cowboy do
  @moduledoc """
  Bridges Cowboy's request format with Ignite's %Conn{} struct.

  Cowboy calls `init/2` for every HTTP request. We convert the Cowboy
  request into an %Ignite.Conn{}, run it through the router, and send
  the response back through Cowboy.
  """
  @behaviour :cowboy_handler

  require Logger

  @impl true
  def init(req, state) do
    # Generate a unique request ID for log correlation and tracing.
    # 16 random bytes → base64url gives a short, URL-safe identifier.
    request_id = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    # Attach request_id to Logger metadata so ALL downstream Logger calls
    # in this process automatically include it — no explicit passing needed.
    Logger.metadata(request_id: request_id)

    # Start the timer — monotonic_time is immune to clock adjustments.
    start_time = System.monotonic_time()

    # Build conn OUTSIDE try — available in rescue for debug context
    conn = cowboy_to_conn(req)
    conn = put_in(conn.private[:request_id], request_id)

    Logger.info("#{conn.method} #{conn.path}")

    req =
      try do
        # 1. Dispatch through the Router
        conn = MyApp.Router.call(conn)

        # 2. Encode the final session before sending cookies
        cookie_value = Ignite.Session.encode(conn.session)

        req =
          :cowboy_req.set_resp_cookie(Ignite.Session.cookie_name(), cookie_value, req, %{
            path: "/",
            http_only: true,
            same_site: :lax
          })

        # 3. Add request ID to response headers for client-side correlation
        resp_headers = Map.put(conn.resp_headers, "x-request-id", request_id)

        # 4. Log the completion with timing
        duration = log_duration(start_time)
        Logger.info("Sent #{conn.status} in #{duration}")

        # 5. Final Cowboy reply
        :cowboy_req.reply(conn.status, resp_headers, conn.resp_body, req)
      rescue
        exception ->
          duration = log_duration(start_time)

          Logger.error("""
          [Ignite] Request crashed (#{duration}):
          #{Exception.format(:error, exception, __STACKTRACE__)}
          """)

          # Render the rich debug page (or generic 500 in prod)
          :cowboy_req.reply(
            500,
            %{"content-type" => "text/html", "x-request-id" => request_id},
            Ignite.DebugPage.render(exception, __STACKTRACE__, conn),
            req
          )
      end

    {:ok, req, state}
  end

  # Calculates elapsed time since `start_time` and formats it as a
  # human-readable string.
  defp log_duration(start_time) do
    diff = System.monotonic_time() - start_time
    micro = System.convert_time_unit(diff, :native, :microsecond)

    cond do
      micro < 1_000 -> "#{micro}µs"
      micro < 1_000_000 -> "#{Float.round(micro / 1_000, 1)}ms"
      true -> "#{Float.round(micro / 1_000_000, 2)}s"
    end
  end


  defp cowboy_to_conn(req) do
    # Read the body if present (POST/PUT/PATCH/DELETE)
    {body_params, req} = 
      case :cowboy_req.header("content-type", req, "") do
        "multipart/form-data" <> _ -> 
          read_multipart(req, %{})
        content_type ->
          {body, req} = read_cowboy_body(req)
          {parse_body(body, content_type), req}
      end

    # Convert Cowboy headers (list of tuples) to a map
    req_headers =
      req.headers
      |> Enum.into(%{}, fn {k, v} -> {String.downcase(k), v} end)

    # --- Step 28: Parse cookies and decode session ---
    cookie_header = Map.get(req_headers, "cookie", "")
    cookies = Ignite.Session.parse_cookies(cookie_header)

    raw_session =
      case Ignite.Session.decode(Map.get(cookies, Ignite.Session.cookie_name())) do
        {:ok, data} -> data
        :error -> %{}
      end

    # Pop flash from session → store in private for get_flash to read.
    # This is the key to one-time-read semantics: flash is removed from
    # the session map so it won't be re-encoded into the response cookie
    # unless put_flash is called again.
    {flash, session} = Map.pop(raw_session, "_flash", %{})

    # After decoding session, ensure a CSRF token exists:
    session =
      if Map.has_key?(session, "_csrf_token") do
        session
      else
        Map.put(session, "_csrf_token", Ignite.CSRF.generate_token())
      end
    # Extract client IP
    {peer_ip_tuple, _peer_port} = :cowboy_req.peer(req)
    peer_ip = peer_ip_tuple |> :inet.ntoa() |> to_string()

    %Ignite.Conn{
      method: req.method,
      path: req.path,
      req_headers: req_headers,
      params: body_params,
      cookies: cookies,
      session: session,
      private: %{flash: flash, peer_ip: peer_ip}
    }
  end


  defp read_cowboy_body(req) do
    case :cowboy_req.has_body(req) do
      true ->
        {:ok, body, req} = :cowboy_req.read_body(req)
        {body, req}

      false ->
        {"", req}
    end
  end

  defp parse_body(body, "application/x-www-form-urlencoded" <> _) do
    URI.decode_query(body)
  end

  defp parse_body(body, "application/json" <> _) when byte_size(body) > 0 do
    case Jason.decode(body) do
      {:ok, parsed} when is_map(parsed) -> parsed
      {:ok, parsed} -> %{"_json" => parsed}
      {:error, _} -> %{"_body" => body}
    end
  end

  defp parse_body(body, _) when byte_size(body) > 0 do
    %{"_body" => body}
  end

  defp parse_body(_, _), do: %{}

  # --- Multipart Handling ---

  defp read_multipart(req, acc) do
    case :cowboy_req.read_part(req) do
      {:ok, headers, req} ->
        # headers = %{"content-disposition" => "form-data; name=\"...\"; filename=\"...\"", ...}
        disposition = Map.get(headers, "content-disposition", "")
        
        case parse_disposition(disposition) do
          {:file, name, filename} ->
            content_type = Map.get(headers, "content-type", "application/octet-stream")
            {path, req} = read_part_to_file(req)
            
            # Setup auto-cleanup when this process dies
            schedule_cleanup(path)
            
            upload = %Ignite.Upload{
              path: path,
              filename: filename,
              content_type: content_type
            }
            read_multipart(req, Map.put(acc, name, upload))

          {:field, name} ->
            {:ok, value, req} = :cowboy_req.read_part_body(req)
            read_multipart(req, Map.put(acc, name, value))

          nil ->
            read_multipart(req, acc)
        end

      {:done, req} ->
        {acc, req}
    end
  end

  defp parse_disposition(disposition) do
    cond do
      disposition =~ "filename=" ->
        [_, name] = Regex.run(~r/name="([^"]+)"/, disposition)
        [_, filename] = Regex.run(~r/filename="([^"]+)"/, disposition)
        {:file, name, filename}
      
      disposition =~ "name=" ->
        [_, name] = Regex.run(~r/name="([^"]+)"/, disposition)
        {:field, name}
      
      true ->
        nil
    end
  end

  defp read_part_to_file(req) do
    tmp_dir = Path.join(System.tmp_dir!(), "ignite-uploads")
    File.mkdir_p!(tmp_dir)
    tmp_path = Path.join(tmp_dir, "upload-#{:erlang.unique_integer([:positive])}")
    
    File.open!(tmp_path, [:write, :binary], fn file ->
      stream_part_body(req, file)
    end)
    
    {tmp_path, req}
  end

  defp stream_part_body(req, file) do
    case :cowboy_req.read_part_body(req) do
      {:ok, data, req} ->
        IO.binwrite(file, data)
        req
      {:more, data, req} ->
        IO.binwrite(file, data)
        stream_part_body(req, file)
    end
  end

  defp schedule_cleanup(path) do
    parent = self()
    spawn(fn ->
      ref = Process.monitor(parent)
      receive do
        {:DOWN, ^ref, :process, ^parent, _reason} ->
          File.rm(path)
      end
    end)
  end
end
