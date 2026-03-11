defmodule Ignite.Server do
  require Logger

  def start(port \\ 4000) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [
      :binary,
      packet: :http,
      active: false,
      reuseaddr: true
    ])

    Logger.info("Ignite is heating up on http://localhost:#{port}")

    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    spawn(fn -> serve(client_socket) end)
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
