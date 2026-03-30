defmodule Ignite.Router do
  @moduledoc """
  Provides macros for defining routes in a clean DSL.

  Supports both static routes:
      get "/hello", to: WelcomeController, action: :hello

  And dynamic routes with named segments:
      get "/users/:id", to: UserController, action: :show

  Dynamic segments (prefixed with `:`) are captured into `conn.params`.
  """

  @doc """
  Defines a scope for grouping routes under a common path prefix.
  Uses AST transformation to prepend the prefix to all nested routes.

  ## Examples

      scope "/api" do
        get "/users", to: UserController, action: :index
      end
  """
  defmacro scope(prefix, do: block) do
    prepend_prefix(block, prefix)
  end

  @doc """
  Called when a module does `use Ignite.Router`.

  Injects a `call/1` function that splits the path into segments
  and dispatches to the matching clause.
  """
  defmacro __using__(_opts) do
    quote do
      import Ignite.Router
      require Logger

      # Register a module attribute to store our list of plugs.
      # accumulate: true means each time we write @plugs it appends to a list.
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)

      # Register @route_info to accumulate route metadata for path helpers
      Module.register_attribute(__MODULE__, :route_info, accumulate: true)
      @before_compile Ignite.Router
    end
  end

  defmacro __before_compile__(env) do
    route_info = Module.get_attribute(env.module, :route_info) |> Enum.reverse()
    plugs = Module.get_attribute(env.module, :plugs) |> Enum.reverse()

    helpers_module = Module.concat(env.module, Helpers)
    helper_functions = Ignite.Router.Helpers.build_helper_functions(route_info)

    # Convert tuples to maps for cleaner access
    routes_list =
      Enum.map(route_info, fn {method, path, controller, action} ->
        %{method: method, path: path, controller: controller, action: action}
      end)

    # Macro.escape/1 converts runtime data into quoted AST that can be embedded
    escaped_routes = Macro.escape(routes_list)

    quote do
      defmodule unquote(helpers_module) do
        unquote_splicing(helper_functions)
      end

      def __routes__, do: unquote(escaped_routes)

      def call(conn) do
        # 1. Run the pipeline of plugs.
        # Since accumulate: true prepends to the list, we reversed it above.
        conn =
          Enum.reduce(unquote(plugs), conn, fn plug_func, acc ->
            # If a previous plug halted the connection, don't run any more.
            if acc.halted do
              acc
            else
              # Call the plug function on the current module
              apply(__MODULE__, plug_func, [acc])
            end
          end)

        # 2. Only dispatch if no plug halted the request
        if conn.halted do
          conn
        else
          # Split "/users/42" into ["users", "42"]
          segments = String.split(conn.path, "/", trim: true)
          dispatch(conn, segments)
        end
      end

      defp dispatch(%Ignite.Conn{} = conn, _segments) do
        %{conn | status: 404, resp_body: "404 - Not Found"}
      end
    end
  end

  @doc """
  Registers a function to be run as part of the middleware pipeline.
  """
  defmacro plug(function_name) do
    quote do
      @plugs unquote(function_name)
    end
  end

  @doc """
  Defines a GET route. Supports static and dynamic segments.

  Static:  get "/hello", to: Ctrl, action: :hello
  Dynamic: get "/users/:id", to: Ctrl, action: :show
  """
  defmacro get(path, to: controller, action: action) do
    build_route("GET", path, controller, action)
  end

  @doc """
  Defines a POST route. Supports static and dynamic segments.
  """
  defmacro post(path, to: controller, action: action) do
    build_route("POST", path, controller, action)
  end

  @doc """
  Defines a PUT route. Supports dynamic segments with `:param`.

  ## Examples

      put "/users/:id", to: UserController, action: :update
  """
  defmacro put(path, to: controller, action: action) do
    build_route("PUT", path, controller, action)
  end

  @doc """
  Defines a PATCH route. Supports dynamic segments with `:param`.

  ## Examples

      patch "/users/:id", to: UserController, action: :update
  """
  defmacro patch(path, to: controller, action: action) do
    build_route("PATCH", path, controller, action)
  end

  @doc """
  Defines a DELETE route. Supports dynamic segments with `:param`.

  ## Examples

      delete "/users/:id", to: UserController, action: :delete
  """
  defmacro delete(path, to: controller, action: action) do
    build_route("DELETE", path, controller, action)
  end

  @doc """
  Defines standard RESTful CRUD routes for a resource.

  ## Examples

      resources "/users", UserController
  """
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

    routes = Enum.flat_map(actions, fn
      :index  -> [quote(do: get(unquote(path), to: unquote(controller), action: :index))]
      :show   -> [quote(do: get(unquote(path <> "/:id"), to: unquote(controller), action: :show))]
      :create -> [quote(do: post(unquote(path), to: unquote(controller), action: :create))]
      :update -> [
        quote(do: put(unquote(path <> "/:id"), to: unquote(controller), action: :update)),
        quote(do: patch(unquote(path <> "/:id"), to: unquote(controller), action: :update))
      ]
      :delete -> [quote(do: delete(unquote(path <> "/:id"), to: unquote(controller), action: :delete))]
    end)

    {:__block__, [], routes}
  end

  # --- Private Macro Helpers ---
  # These run at compile time to generate the dispatch function clauses.

  defp build_route(method, path, controller, action) do
    # Split the route path into segments at compile time
    # e.g. "/users/:id" => ["users", ":id"]
    segments = path |> String.split("/", trim: true)

    # Build the list pattern for matching, e.g. ["users", id]
    # where :id becomes a variable `id`
    match_pattern = build_match_pattern(segments)

    # Build the params map to inject into conn, e.g. %{id: id}
    params_map = build_params_map(segments)

    quote do
      @route_info {unquote(method), unquote(path), unquote(controller), unquote(action)}

      defp dispatch(%Ignite.Conn{method: unquote(method)} = conn, unquote(match_pattern)) do
        conn = %Ignite.Conn{conn | params: Map.merge(conn.params, unquote(params_map))}
        apply(unquote(controller), unquote(action), [conn])
      end

      # Automatically handle HEAD for any defined GET route
      if unquote(method) == "GET" do
        defp dispatch(%Ignite.Conn{method: "HEAD"} = conn, unquote(match_pattern)) do
          conn = %Ignite.Conn{conn | params: Map.merge(conn.params, unquote(params_map))}
          apply(unquote(controller), unquote(action), [conn])
        end
      end
    end
  end

  # Converts route segments into an Elixir list pattern for matching.
  #
  # "users"  -> quoted literal string "users" (must match exactly)
  # ":id"    -> quoted variable `id` (matches anything, captures value)
  #
  # Result: a quoted list like ["users", id] usable in function heads.
  defp build_match_pattern(segments) do
    Enum.map(segments, fn segment ->
      if String.starts_with?(segment, ":") do
        # Strip the ":" prefix and create a variable AST node
        var_name = segment |> String.slice(1..-1//1) |> String.to_atom()
        Macro.var(var_name, nil)
      else
        # Keep it as a literal string to match exactly
        segment
      end
    end)
  end

  # Builds a quoted params map from the dynamic segments.
  #
  # [":id", ":name"] -> %{id: id, name: name}
  #
  # This map is merged into conn.params at runtime.
  defp build_params_map(segments) do
    pairs =
      segments
      |> Enum.filter(&String.starts_with?(&1, ":"))
      |> Enum.map(fn segment ->
        var_name = segment |> String.slice(1..-1//1) |> String.to_atom()
        {var_name, Macro.var(var_name, nil)}
      end)

    {:%{}, [], pairs}
  end

  # --- AST Transformation Helpers ---

  # A block with multiple expressions: transform each one
  defp prepend_prefix({:__block__, meta, exprs}, prefix) do
    {:__block__, meta, Enum.map(exprs, &prepend_prefix(&1, prefix))}
  end

  # Route macros: prepend prefix to the path argument
  defp prepend_prefix({method, meta, [path | rest]}, prefix)
       when method in [:get, :post, :put, :patch, :delete] and is_binary(path) do
    {method, meta, [prefix <> path | rest]}
  end

  # Resource macro: prepend prefix to the path argument
  defp prepend_prefix({:resources, meta, [path | rest]}, prefix)
       when is_binary(path) do
    {:resources, meta, [prefix <> path | rest]}
  end

  # Nested scope: prepend prefix to the inner scope's prefix
  defp prepend_prefix({:scope, meta, [inner_prefix | rest]}, prefix)
       when is_binary(inner_prefix) do
    {:scope, meta, [prefix <> inner_prefix | rest]}
  end

  # Anything else: pass through unchanged
  defp prepend_prefix(expr, _prefix), do: expr
end
