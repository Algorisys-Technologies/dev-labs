defmodule Ignite.Server do
  @moduledoc """
  The HTTP server, implemented as an OTP GenServer.

  Using GenServer gives us two things:
  1. A standard `start_link/1` interface that Supervisors expect
  2. The `handle_continue` callback so `init` returns quickly

  The Supervisor in application.ex will start and monitor this process
  automatically when the app boots.
  """

  use GenServer
  require Logger

  # --- Client API ---
  # Called by the Supervisor. The name: __MODULE__ means the process
  # registers itself globally as Ignite.Server, so you can find it with
  # Process.whereis(Ignite.Server).

  def start_link(port \\ 4000) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(port) do
    # Return immediately so the Supervisor doesn't wait.
    # {:continue, :listen} tells the BEAM: "call handle_continue(:listen, ...)
    # right after init returns".
    {:ok, %{port: port, listen_socket: nil}, {:continue, :listen}}
  end

  @impl true
  def handle_continue(:listen, %{port: port} = state) do
    # Open the TCP socket here (slow operation, done outside init).
    {:ok, listen_socket} = :gen_tcp.listen(port, [
      :binary,
      packet: :http,
      active: false,
      reuseaddr: true
    ])

    Logger.info("Ignite is heating up on http://localhost:#{port}")

    # spawn_link creates a process LINKED to this GenServer.
    # If the acceptor loop crashes → this GenServer crashes → Supervisor restarts everything.
    spawn_link(fn -> loop_acceptor(listen_socket) end)

    {:noreply, %{state | listen_socket: listen_socket}}
  end

  # --- Private Functions ---

  # Infinite loop: waits for a browser to connect, spawns a Task to handle
  # the request, immediately loops back to wait for the next one.
  defp loop_acceptor(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    # Task.start is like spawn but integrates properly with OTP.
    # It is NOT linked — if one request crashes, others keep going.
    Task.start(fn -> serve(client_socket) end)

    loop_acceptor(listen_socket)
  end

  defp serve(client_socket) do
    try do
      # Parse → Route → Respond
      conn = Ignite.Parser.parse(client_socket)

      Logger.info("Received: #{conn.method} #{conn.path}")

      conn = MyApp.Router.call(conn)

      response = Ignite.Controller.send_resp(conn)
      :gen_tcp.send(client_socket, response)
      :gen_tcp.close(client_socket)
    catch
      :throw, :closed ->
        # Client disconnected before sending a full request — close silently
        :gen_tcp.close(client_socket)
    end
  end
end
