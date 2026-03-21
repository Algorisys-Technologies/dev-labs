# lib/my_app/live/presence_demo_live.ex
defmodule MyApp.PresenceDemoLive do
  use Ignite.LiveView
  require Logger
  alias Ignite.Presence
  alias Ignite.PubSub

  @topic "presence:demo"
  def topic, do: @topic

  @impl true
  def mount(_params, _session) do
    username = "user_#{:rand.uniform(9999)}"
    joined_at = DateTime.utc_now() |> DateTime.to_string()

    # ONLY track if we are connected (WebSocket)
    is_connected = Ignite.LiveView.connected?(self())
    Logger.error("[PresenceDemoLive] mount connected?=#{is_connected}")

    if is_connected do
      Presence.track(@topic, username, %{joined_at: joined_at})
    end

    online = Presence.list(@topic)
    Logger.error("[PresenceDemoLive] online list size=#{map_size(online)}")
    {:ok, %{username: username, online: online}}
  end

  @impl true
  def handle_event(_event, _params, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info({:pubsub, @topic, {:presence_diff, _diff}}, assigns) do
    # Simply fetch the full list on any change for this demo
    online = Presence.list(@topic)
    {:noreply, %{assigns | online: online}}
  end

  @impl true
  def render(assigns) do
    user_count = map_size(assigns.online)

    users_html =
      assigns.online
      |> Enum.sort_by(fn {_k, meta} -> meta.joined_at end)
      |> Enum.map(fn {name, meta} ->
        is_me = name == assigns.username
        badge = if is_me, do: " <span style=\"color:#27ae60;font-weight:bold;\">(you)</span>", else: ""

        """
        <li style="padding:8px 12px;border-bottom:1px solid #eee;display:flex;justify-content:space-between;align-items:center;">
          <span>#{name}#{badge}</span>
          <span style="color:#888;font-size:12px;">joined #{meta.joined_at}</span>
        </li>
        """
      end)
      |> Enum.join("\n")

    ~L"""
    <div id="presence-demo" style="max-width:550px;margin:20px auto;font-family:system-ui;">
      <h1>Who's Online</h1>
      <p style="color:#666;font-size:14px;margin-bottom:20px;">
        Open this page in multiple tabs — users appear/disappear in real time.
      </p>

      <div style="background:#f0f7ff;padding:16px;border-radius:12px;margin-bottom:20px;border:1px solid #cce3ff;">
        You are: <strong><%= assigns.username %></strong>
        <span style="margin:0 15px;color:#ccc;">|</span>
        Online: <strong><%= user_count %></strong>
      </div>

      <ul style="list-style:none;padding:0;margin:0;background:#fff;border:1px solid #ddd;border-radius:12px;overflow:hidden;box-shadow:0 4px 6px -1px rgb(0 0 0 / 0.1);">
        <%= users_html %>
      </ul>
    </div>
    """
  end
end
