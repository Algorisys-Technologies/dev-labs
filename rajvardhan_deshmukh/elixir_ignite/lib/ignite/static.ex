defmodule Ignite.Static do
  @moduledoc """
  Manages static asset versions using content hashing and an ETS manifest for fast lookups.
  """

  @table :ignite_static_manifest
  @default_dir "assets"

  @doc """
  Initializes the static manifest ETS table and scans assets.
  """
  def init(dir \\ @default_dir) do
    if :ets.info(@table) != :undefined do
      :ets.delete_all_objects(@table)
    else
      :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    end

    build_manifest(dir)
  end

  @doc """
  Rebuilds the manifest by re-scanning assets (used by hot reloader).
  """
  def rebuild(dir \\ @default_dir) do
    :ets.delete_all_objects(@table)
    build_manifest(dir)
  end

  @doc """
  Returns a hashed path for the given asset (e.g., /assets/app.js?v=a1b2c3d4).
  """
  def static_path(filename) do
    case :ets.lookup(@table, filename) do
      [{^filename, hash}] -> "/assets/#{filename}?v=#{hash}"
      [] -> "/assets/#{filename}"
    end
  end

  defp build_manifest(dir) do
    if File.dir?(dir) do
      dir
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
      |> Enum.each(fn path ->
        filename = Path.relative_to(path, dir)
        hash = hash_file(path)
        :ets.insert(@table, {filename, hash})
      end)
    end
  end

  defp hash_file(path) do
    path
    |> File.read!()
    |> :erlang.md5()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end
end
