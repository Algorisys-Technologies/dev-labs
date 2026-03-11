defmodule Ignite.Server do
  def start(port \\ 4000) do
    # 1. Open the front door on port 4000
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, packet: :http, active: false, reuseaddr: true])

    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(listen_socket) do
    # 2. Wait for a customer to walk in
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)

    # 3. Handle the customer (we create a new 'process' for every single person)
    spawn(fn ->
      # 1. Parse
      case Ignite.Parser.parse(client_socket) do
        {:error, _reason} ->
          # Browser closed the connection before sending data, just close our end silently
          :gen_tcp.close(client_socket)

        conn ->
          # 2. Route
          conn = MyApp.Router.call(conn)

          # 3. Respond
          response = Ignite.Controller.send_resp(conn)
          :gen_tcp.send(client_socket, response)
          :gen_tcp.close(client_socket)
      end
    end)

    # 4. Wait for the next customer
    loop_acceptor(listen_socket)
  end
end
