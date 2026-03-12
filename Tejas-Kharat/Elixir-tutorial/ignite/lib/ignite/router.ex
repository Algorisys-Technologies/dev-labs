defmodule Ignite.Router do
  defmacro __using__(_opts) do
    quote do
      import Ignite.Router

      # Accumulate plug names as a module attribute.
      # `accumulate: true` means each `@plugs :name` adds to a list.
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)

      # Generate call/1 after all plugs and routes are defined.
      # This ensures @plugs is fully accumulated when call/1 is compiled.
      @before_compile Ignite.Router
    end
  end

  defmacro plug(function_name) do
    quote do
      @plugs unquote(function_name)
    end
  end

  defmacro __before_compile__(env) do
    plugs = Module.get_attribute(env.module, :plugs) |> Enum.reverse()

    quote do
      def call(conn) do
        conn =
          Enum.reduce(unquote(plugs), conn, fn plug_func, acc ->
            if acc.halted, do: acc, else: apply(__MODULE__, plug_func, [acc])
          end)

        if conn.halted do
          conn
        else
          segments = String.split(conn.path, "/", trim: true)
          dispatch(conn, segments)
        end
      end
    end
  end

  defmacro get(path, to: controller, action: action) do
    build_route("GET", path, controller, action)
  end

  defmacro post(path, to: controller, action: action) do
    build_route("POST", path, controller, action)
  end

  defp build_route(method, path, controller, action) do
    segments = String.split(path, "/", trim: true)
    {match_pattern, param_names} = build_match_pattern(segments)

    quote do
      defp dispatch(
             %Ignite.Conn{method: unquote(method)} = conn,
             unquote(match_pattern)
           ) do
        params = unquote(build_params_map(param_names))
        conn = %Ignite.Conn{conn | params: Map.merge(conn.params, params)}
        apply(unquote(controller), unquote(action), [conn])
      end
    end
  end

  defp build_match_pattern(segments) do
    {patterns, names} =
      Enum.map(segments, fn
        ":" <> name ->
          # Dynamic segment: create a variable that captures the value
          var_name = String.to_atom(name)
          {Macro.var(var_name, nil), var_name}

        static ->
          # Static segment: must match this exact string
          {static, nil}
      end)
      |> Enum.unzip()

    {patterns, Enum.reject(names, &is_nil/1)}
  end

  defp build_params_map(param_names) do
    pairs =
      Enum.map(param_names, fn name ->
        {name, Macro.var(name, nil)}
      end)

    {:%{}, [], pairs}
  end

  defmacro finalize_routes() do
    quote do
      defp dispatch(conn, _segments) do
        Ignite.Controller.text(conn, "404 - Not Found", 404)
      end
    end
  end
end
