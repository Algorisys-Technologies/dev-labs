defmodule MyApp.PresenceDemoLive do
  use Ignite.LiveView

  @topic "presence:demo"

  @impl true
  def mount(_params, _session) do
    username = "user_#{:rand.uniform(9999)}"

    # Subscribe to presence diffs on this topic
    Ignite.PubSub.subscribe(@topic)

    # Track this LiveView process under the topic
    Ignite.Presence.track(@topic, username, %{
      joined_at: DateTime.utc_now() |> DateTime.to_string()
    })

    # Fetch initial list of everyone online
    online = Ignite.Presence.list(@topic)

    {:ok, %{username: username, online: online}}
  end

  @impl true
  def handle_event(_event, _params, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info({:presence_diff, _diff}, assigns) do
    # On any presence change, refresh the full list
    online = Ignite.Presence.list(@topic)
    {:noreply, %{assigns | online: online}}
  end

  @impl true
  def render(assigns) do
    user_count = map_size(assigns.online)

    users_html =
      Enum.map_join(assigns.online, "\n", fn {name, meta} ->
        joined = Map.get(meta, :joined_at, "unknown")
        is_self = name == assigns.username

        badge =
          if is_self,
            do: " <span style=\"background:#722f37; color:white; padding:2px 8px; border-radius:10px; font-size:0.75em;\">YOU</span>",
            else: ""

        """
        <div style="display: flex; align-items: center; padding: 12px 16px; background: white;
                    border: 1px solid #eee; border-radius: 8px; margin-bottom: 8px;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
          <div style="width: 10px; height: 10px; background: #00b894; border-radius: 50%;
                      margin-right: 12px; box-shadow: 0 0 6px rgba(0,184,148,0.5);"></div>
          <div style="flex: 1;">
            <strong style="font-size: 0.95em;">#{name}</strong>#{badge}
            <div style="font-size: 0.75em; color: #b2bec3; margin-top: 2px;">joined #{joined}</div>
          </div>
        </div>
        """
      end)

    ~L"""
    <div id="presence-demo" style="max-width: 500px; margin: 40px auto; padding: 30px;
                                    background: #faf9f6; border-radius: 16px;
                                    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
                                    font-family: 'Inter', sans-serif; color: #333;">
      <h2 style="text-align: center; color: #722f37; margin-bottom: 5px;">Who's Online</h2>
      <p style="text-align: center; color: #b2bec3; font-size: 0.85em; margin-bottom: 25px;">
        <%= user_count %> user(s) connected
      </p>

      <div id="user-list">
        <%= users_html %>
      </div>

      <div style="margin-top: 25px; padding-top: 15px; border-top: 1px solid #eee;
                  text-align: center; font-size: 0.8em; color: #b2bec3;">
        You are <strong style="color: #722f37;"><%= assigns.username %></strong> ·
        <a href="/" style="color: #722f37; text-decoration: none;">← Back</a>
      </div>
    </div>
    """
  end
end
