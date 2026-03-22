defmodule Ignite.Server do
  use GenServer
  require Logger

  def start_link(opts) do
    port = Keyword.get(opts, :port, 4000)
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    # 1. Open the front door on port 4000
    # active: false means we pull data manually (Step 1 requirement)
    case :gen_tcp.listen(port, [:binary, packet: :http, active: false, reuseaddr: true]) do
      {:ok, listen_socket} ->
        Logger.info("Ignite server started on port #{port}")
        # Start accepting in the background so we don't block the supervisor
        send(self(), :accept)
        {:ok, %{listen_socket: listen_socket}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_info(:accept, state) do
    # 2. Wait for a customer to walk in (non-blocking for the system, but this process waits)
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, client_socket} ->
        # 3. Handle the customer (we create a new 'process' for every single person)
        spawn(fn -> handle_client(client_socket) end)
        
        # 4. Wait for the next customer
        send(self(), :accept)
        {:noreply, state}

      {:error, _reason} ->
        send(self(), :accept)
        {:noreply, state}
    end
  end

  defp handle_client(client_socket) do
    # 1. Parse
    case Ignite.Parser.parse(client_socket) do
      {:error, _reason} ->
        :gen_tcp.close(client_socket)

      conn ->
        # Check for WebSocket upgrade
        if Map.get(conn.headers, "upgrade", "") |> String.downcase() == "websocket" do
          handle_websocket_upgrade(client_socket, conn)
        else
          # 2. Route
          conn = MyApp.Router.call(conn)

          # 3. Respond
          response = Ignite.Controller.send_resp(conn)
          :gen_tcp.send(client_socket, response)
          :gen_tcp.close(client_socket)
        end
    end
  end

  defp handle_websocket_upgrade(socket, conn) do
    key = Map.get(conn.headers, "sec-websocket-key")
    accept_key = calculate_accept_key(key)

    response =
      "HTTP/1.1 101 Switching Protocols\r\n" <>
      "Upgrade: websocket\r\n" <>
      "Connection: Upgrade\r\n" <>
      "Sec-WebSocket-Accept: #{accept_key}\r\n\r\n"

    :gen_tcp.send(socket, response)
    
    # Transition to non-blocking mode
    :inet.setopts(socket, packet: :raw, active: true)
    websocket_loop(socket, %{live_pid: nil})
  end

  defp calculate_accept_key(key) do
    guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    :crypto.hash(:sha, key <> guid) |> Base.encode64()
  end

  defp websocket_loop(socket, state) do
    receive do
      {:tcp, ^socket, data} ->
        case Ignite.Websocket.decode(data) do
          {:ok, payload, _rest} ->
            case handle_ws_msg(socket, Jason.decode!(payload), state) do
              {:ok, new_state} -> websocket_loop(socket, new_state)
              {:stop, _reason} -> :gen_tcp.close(socket)
            end

          {:close, _} ->
            if state.live_pid, do: GenServer.stop(state.live_pid)
            :gen_tcp.close(socket)

          _ ->
            websocket_loop(socket, state)
        end

      {:render, html} ->
        msg = Jason.encode!(%{topic: "lv:update", payload: %{html: html}})
        :gen_tcp.send(socket, Ignite.Websocket.encode(msg))
        websocket_loop(socket, state)

      {:tcp_closed, ^socket} ->
        if state.live_pid, do: GenServer.stop(state.live_pid)
        :ok

      {:error, _reason} ->
        if state.live_pid, do: GenServer.stop(state.live_pid)
        :gen_tcp.close(socket)
    end
  end

  defp handle_ws_msg(socket, %{"topic" => "lv:join", "payload" => %{"module" => mod_str}}, state) do
    module = String.to_existing_atom(mod_str)
    
    # 1. Spawn the stateful LiveView process
    {:ok, pid} = Ignite.LiveView.Process.start_link(
      module: module,
      socket_pid: self()
    )

    # 2. Return the new state
    {:ok, %{state | live_pid: pid}}
  end

  defp handle_ws_msg(_socket, %{"topic" => "lv:event", "payload" => %{"event" => event, "params" => params}}, state) do
    # Forward to the LiveView process
    if state.live_pid do
      GenServer.cast(state.live_pid, {:event, event, params})
    end
    {:ok, state}
  end

  defp handle_ws_msg(_socket, _, state), do: {:ok, state}
end
