defmodule Ignite.Router do
  defmacro __using__(_opts) do
    quote do
      import Ignite.Router

      # Accumulate plug names as a module attribute.
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)

      # Accumulate route metadata for path helpers.
      Module.register_attribute(__MODULE__, :route_info, accumulate: true)

      # Generate call/1 and helpers after all routes are defined.
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
    route_info = Module.get_attribute(env.module, :route_info) |> Enum.reverse()

    helpers_module = Module.concat(env.module, Helpers)
    helper_functions = Ignite.Router.Helpers.build_helper_functions(route_info)

    # Convert tuples to maps for cleaner access
    routes_list =
      Enum.map(route_info, fn {method, path, controller, action} ->
        %{method: method, path: path, controller: controller, action: action}
      end)

    escaped_routes = Macro.escape(routes_list)

    quote do
      defmodule unquote(helpers_module) do
        unquote_splicing(helper_functions)
      end

      def __routes__, do: unquote(escaped_routes)

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

  defmacro put(path, to: controller, action: action) do
    build_route("PUT", path, controller, action)
  end

  defmacro patch(path, to: controller, action: action) do
    build_route("PATCH", path, controller, action)
  end

  defmacro delete(path, to: controller, action: action) do
    build_route("DELETE", path, controller, action)
  end

  defmacro resources(path, controller, opts \\ []) do
    only = Keyword.get(opts, :only, nil)
    except = Keyword.get(opts, :except, [])
    all_actions = [:index, :show, :create, :update, :delete]

    actions =
      if only do
        Enum.filter(all_actions, &(&1 in only))
      else
        Enum.reject(all_actions, &(&1 in except))
      end

    routes =
      Enum.flat_map(actions, fn
        :index ->
          [quote(do: get(unquote(path), to: unquote(controller), action: :index))]

        :show ->
          [quote(do: get(unquote(path <> "/:id"), to: unquote(controller), action: :show))]

        :create ->
          [quote(do: post(unquote(path), to: unquote(controller), action: :create))]

        :update ->
          [
            quote(do: put(unquote(path <> "/:id"), to: unquote(controller), action: :update)),
            quote(do: patch(unquote(path <> "/:id"), to: unquote(controller), action: :update))
          ]

        :delete ->
          [quote(do: delete(unquote(path <> "/:id"), to: unquote(controller), action: :delete))]
      end)

    {:__block__, [], routes}
  end

  defmacro scope(prefix, do: block) do
    prepend_prefix(block, prefix)
  end

  defp prepend_prefix({:__block__, meta, exprs}, prefix) do
    {:__block__, meta, Enum.map(exprs, &prepend_prefix(&1, prefix))}
  end

  defp prepend_prefix({method, meta, [path | rest]}, prefix)
       when method in [:get, :post, :put, :patch, :delete] and is_binary(path) do
    {method, meta, [prefix <> path | rest]}
  end

  defp prepend_prefix({:scope, meta, [inner_prefix | rest]}, prefix)
       when is_binary(inner_prefix) do
    {:scope, meta, [prefix <> inner_prefix | rest]}
  end

  defp prepend_prefix({:resources, meta, [path | rest]}, prefix)
       when is_binary(path) do
    {:resources, meta, [prefix <> path | rest]}
  end

  defp prepend_prefix(expr, _prefix), do: expr

  defp build_route(method, path, controller, action) do
    segments = String.split(path, "/", trim: true)
    {match_pattern, param_names} = build_match_pattern(segments)

    quote do
      @route_info {unquote(method), unquote(path), unquote(controller), unquote(action)}

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
