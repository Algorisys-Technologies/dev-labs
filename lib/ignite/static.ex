defmodule Ignite.Static do
  @moduledoc """
  Handles cache-busting for static assets.

  Computes MD5 hashes for all files in the assets directory at boot time
  and stores them in an ETS table for O(1) lookups during template rendering.
  """

  require Logger

  @table :ignite_static_manifest
  @default_dir "assets"

  @doc """
  Initializes the static manifest ETS table and scans the assets directory.
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
  Clears and rebuilds the static manifest. Called by the reloader in dev.
  """
  def rebuild(dir \\ @default_dir) do
    :ets.delete_all_objects(@table)
    build_manifest(dir)
  end

  @doc """
  Returns the hashed path for a static asset.
  Example: static_path("ignite.js") -> "/assets/ignite.js?v=a1b2c3d4"
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
    else
      Logger.warning("[Ignite.Static] Assets directory not found: #{dir}")
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
