defmodule Ignite.Server do
  use GenServer
  require Logger

  # --- Client API ---
  # Called by the supervisor to start us.

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(port) do
    # Return fast so the supervisor isn't blocked.
    # handle_continue runs immediately after.
    {:ok, %{port: port}, {:continue, :listen}}
  end

  @impl true
  def handle_continue(:listen, %{port: port} = state) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [
      :binary,
      packet: :http,
      active: false,
      reuseaddr: true
    ])

    Logger.info("Ignite is heating up on http://localhost:#{port}")

    # Linked process: if the acceptor crashes, we crash too,
    # so the supervisor can restart both.
    spawn_link(fn -> loop_acceptor(listen_socket) end)

    {:noreply, Map.put(state, :listen_socket, listen_socket)}
  end

  # --- Private Functions ---

  defp loop_acceptor(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    Task.start(fn -> serve(client_socket) end)
    loop_acceptor(listen_socket)
  end

  defp serve(client_socket) do
    conn = Ignite.Parser.parse(client_socket)
    Logger.info("#{conn.method} #{conn.path}")

    conn = MyApp.Router.call(conn)
    response = Ignite.Controller.send_resp(conn)
    :gen_tcp.send(client_socket, response)
    :gen_tcp.close(client_socket)
  end
end
