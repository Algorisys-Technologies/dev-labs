defmodule Ignite.Router do
  defmacro __using__(_opts) do
    quote do
      import Ignite.Router
      def call(conn) do
        dispatch(conn)
      end
    end
  end

  defmacro get(path, to: controller, action: action) do
    quote do
      defp dispatch(%Ignite.Conn{method: "GET", path: unquote(path)} = conn) do
        apply(unquote(controller), unquote(action), [conn])
      end
    end
  end

  defmacro finalize_routes() do
    quote do
      defp dispatch(conn) do
        %{conn | status: 404, resp_body: "404 — Not Found"}
      end
    end
  end
end
