# reproduce_presence.exs
IO.puts "Reproducing Presence Issue..."
:pg.start_link()
Ignite.Presence.start_link()

topic = "test"

# 1. Start Process A
parent = self()
pid_a = spawn(fn ->
  Ignite.Presence.track(topic, "user_a", %{m: "a"})
  send(parent, :tracked_a)
  Process.sleep(:infinity)
end)

receive do: (:tracked_a -> :ok)

# 2. Start Process B
pid_b = spawn(fn ->
  Ignite.Presence.track(topic, "user_b", %{m: "b"})
  send(parent, :tracked_b)
  Process.sleep(:infinity)
end)

receive do: (:tracked_b -> :ok)

# 3. List
online = Ignite.Presence.list(topic)
IO.puts "Online members: #{inspect(online)}"
IO.puts "Count: #{map_size(online)}"

if map_size(online) == 2 do
  IO.puts "✅ Presence tracking works for multiple processes"
else
  IO.puts "❌ Presence tracking FAILED to show 2 processes"
end

# 4. Kill A and see if B remains
Process.exit(pid_a, :kill)
Process.sleep(100)
online_after = Ignite.Presence.list(topic)
IO.puts "Online after A dies: #{inspect(online_after)}"

if map_size(online_after) == 1 and Map.has_key?(online_after, "user_b") do
  IO.puts "✅ Correctly removed A and kept B"
else
  IO.puts "❌ Cleanup FAILED"
end
