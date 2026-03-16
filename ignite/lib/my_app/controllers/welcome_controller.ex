defmodule MyApp.WelcomeController do
  import Ignite.Controller

  @live_routes Jason.encode!(%{
    "/counter" => "/live",
    "/dashboard" => "/live/dashboard",
    "/shared-counter" => "/live/shared-counter",
    "/components" => "/live/components",
    "/hooks" => "/live/hooks"
  })

  def index(conn), do: text(conn, "Welcome to Ignite!")

  def crash(_conn) do
    raise "This is a test crash!"
  end

  def counter(conn) do
    render(conn, "live", title: "Live Counter — Ignite", live_routes: @live_routes)
  end

  def dashboard(conn) do
    render(conn, "live", title: "Dashboard — Ignite", live_path: "/live/dashboard", live_routes: @live_routes)
  end

  def shared_counter(conn) do
    render(conn, "live", title: "Shared Counter — Ignite", live_path: "/live/shared-counter", live_routes: @live_routes)
  end

  def components(conn) do
    render(conn, "live", title: "Live Components — Ignite", live_path: "/live/components", live_routes: @live_routes)
  end

  def hooks(conn) do
    render(conn, "live", title: "JS Hooks — Ignite", live_path: "/live/hooks", live_routes: @live_routes)
  end
end
