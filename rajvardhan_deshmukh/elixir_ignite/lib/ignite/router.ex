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
  Called when a module does `use Ignite.Router`.

  Injects a `call/1` function that splits the path into segments
  and dispatches to the matching clause.
  """
  defmacro __using__(_opts) do
    quote do
      import Ignite.Router

      def call(conn) do
        # Split "/users/42" into ["users", "42"]
        # trim: true removes the empty string caused by the leading "/"
        segments = String.split(conn.path, "/", trim: true)
        dispatch(conn, segments)
      end
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
  Generates the catch-all 404 clause. Must be called last.
  """
  defmacro finalize_routes do
    quote do
      defp dispatch(conn, _segments) do
        %Ignite.Conn{conn | status: 404, resp_body: "404 — Not Found"}
      end
    end
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
      defp dispatch(%Ignite.Conn{method: unquote(method)} = conn, unquote(match_pattern)) do
        conn = %Ignite.Conn{conn | params: Map.merge(conn.params, unquote(params_map))}
        apply(unquote(controller), unquote(action), [conn])
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
end
