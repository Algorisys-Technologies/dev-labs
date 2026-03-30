defmodule Mix.Tasks.Ignite.Routes do
  @shortdoc "Prints all routes for the router"

  @moduledoc """
  Prints all routes for the given router.

      $ mix ignite.routes
      $ mix ignite.routes MyApp.Router

  If no router module is given, defaults to `MyApp.Router`.
  """

  use Mix.Task

  @impl true
  def run(args) do
    # 1. Compile the project to ensure routes are up to date
    Mix.Task.run("compile", [])

    # 2. Determine which router to inspect
    router =
      case args do
        [module_str | _] -> Module.concat([module_str])
        [] -> MyApp.Router
      end

    # 3. Load the module into the VM so we can call its functions
    Code.ensure_loaded!(router)

    # 4. Verify it's an Ignite router with exposed routes
    if function_exported?(router, :__routes__, 0) do
      routes = router.__routes__()

      if routes == [] do
        Mix.shell().info("No routes found in #{inspect(router)}")
      else
        print_routes(routes)
      end
    else
      Mix.raise("""
      Module #{inspect(router)} does not define __routes__/0.

      Make sure the module uses `Ignite.Router` and defines at least one route.
      """)
    end
  end

  defp print_routes(routes) do
    # Calculate column widths for nice alignment
    method_width = routes |> Enum.map(&String.length(&1.method)) |> Enum.max() |> max(6)
    path_width = routes |> Enum.map(&String.length(&1.path)) |> Enum.max()
    ctrl_width = routes |> Enum.map(&(inspect(&1.controller) |> String.length())) |> Enum.max()

    Enum.each(routes, fn %{method: method, path: path, controller: ctrl, action: action} ->
      line =
        String.pad_trailing(method, method_width + 2) <>
          String.pad_trailing(path, path_width + 2) <>
          String.pad_trailing(inspect(ctrl), ctrl_width + 2) <>
          inspect(action)

      Mix.shell().info(line)
    end)
  end
end
