defmodule Ignite.Static do
  @moduledoc """
  Provides cache-busting for static assets based on content hashing.
  """

  @table :ignite_static_manifest
  @default_dir "assets"

  @doc """
  Initializes the static manifest by scanning the assets directory and
  computing hashes for all files. Stores them in an ETS table.
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
  Clears and rebuilds the manifest. Called by the reloader in development.
  """
  def rebuild(dir \\ @default_dir) do
    :ets.delete_all_objects(@table)
    build_manifest(dir)
  end

  @doc """
  Returns the versioned path for a static asset.
  Example: "ignite.js" -> "/assets/ignite.js?v=a1b2c3d4"
  """
  def static_path(filename) do
    case :ets.lookup(@table, filename) do
      [{^filename, hash}] -> "/assets/#{filename}?v=#{hash}"
      [] -> "/assets/#{filename}"
    end
  end

  defp build_manifest(dir) do
    # Scan for all regular files in the directory recursively
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

  defp hash_file(path) do
    # Compute MD5 and take first 8 hex characters
    path
    |> File.read!()
    |> :erlang.md5()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end
end
