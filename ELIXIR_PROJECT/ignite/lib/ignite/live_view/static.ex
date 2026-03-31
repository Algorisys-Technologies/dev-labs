defmodule Ignite.LiveView.Static do
  import Ignite.Controller

  def render(conn, module, params) do
    # 1. Mount the LiveView (initial state)
    {:ok, assigns} = module.mount(params, %{})

    # 2. Render the initial state (use engine to normalize string vs %Rendered)
    rendered = Ignite.LiveView.Engine.render(module, assigns)
    
    # 3. Convert Rendered to full HTML string for initial page load
    content = full_html(rendered)

    # 4. Handle the layout and metadata
    # We no longer wrap in an inner ignite-root here, because 
    # templates/live.eex already provides the wrapper.
    live_routes = Map.get(params, "_live_routes", "{}")

    # 5. Return the full HTML page using our base template (live.eex)
    Ignite.Controller.render(conn, "live", 
      body: content, 
      module: module, 
      rendered: Jason.encode!(Ignite.LiveView.Diff.calculate(nil, rendered)), 
      live_routes: live_routes
    )
  end

  defp full_html(%Ignite.LiveView.Rendered{statics: statics, dynamics: dynamics}) do
    interleave(statics, dynamics)
  end

  defp full_html(other), do: to_string(other)

  defp interleave([s | statics], [d | dynamics]) do
    s <> full_html(d) <> interleave(statics, dynamics)
  end

  defp interleave([s], []), do: s
  defp interleave([], []), do: ""
end
