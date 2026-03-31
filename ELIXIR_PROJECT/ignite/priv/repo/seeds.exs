alias MyApp.{Repo, Category}

# Only seed if categories table is empty
if Repo.aggregate(Category, :count) == 0 do
  categories = [
    %{name: "Work",      color: "#5c6bc0"},
    %{name: "Personal",  color: "#26a69a"},
    %{name: "Education", color: "#ef5350"},
    %{name: "Health",    color: "#66bb6a"},
    %{name: "Shopping",  color: "#ffa726"},
    %{name: "Other",     color: "#78909c"}
  ]

  for attrs <- categories do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert!()
  end

  IO.puts("✅ Seeded #{length(categories)} categories")
else
  IO.puts("ℹ️  Categories already exist, skipping seed")
end
