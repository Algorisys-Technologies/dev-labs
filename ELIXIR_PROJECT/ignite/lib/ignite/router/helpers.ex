# lib/ignite/router/helpers.ex
defmodule Ignite.Router.Helpers do
  @moduledoc """
  Generates path helper functions from accumulated route metadata.
  """

  def derive_name("/"), do: :root_path

  def derive_name(path) do
    segments =
      path
      |> String.split("/", trim: true)
      |> Enum.reject(&String.starts_with?(&1, ":"))

    case segments do
      [] ->
        :root_path

      segs ->
        last = List.last(segs) |> naive_singularize()
        prefix = Enum.drop(segs, -1)

        name =
          (prefix ++ [last])
          |> Enum.join("_")

        String.to_atom(name <> "_path")
    end
  end

  def build_helper_functions(route_info) do
    route_info
    |> Enum.map(fn {_method, path, _controller, action} ->
      helper_name = derive_name(path)
      dynamic_segments = extract_dynamic_segments(path)
      {helper_name, action, path, dynamic_segments}
    end)
    # Deduplicate: PUT/PATCH both map to :update with same path
    |> Enum.uniq_by(fn {name, action, _path, _dynamics} -> {name, action} end)
    |> Enum.map(&build_function_clause/1)
  end

  def naive_singularize(word) do
    cond do
      String.ends_with?(word, "ses") and
          Regex.match?(~r/(ss|sh|ch|x|z)es$/, word) ->
        String.replace_trailing(word, "es", "")

      String.ends_with?(word, "ses") ->
        String.replace_trailing(word, "es", "")

      String.ends_with?(word, "ies") ->
        String.replace_trailing(word, "ies", "y")

      Regex.match?(~r/(ss|us|is|os)$/, word) ->
        word

      String.ends_with?(word, "s") ->
        String.replace_trailing(word, "s", "")

      true ->
        word
    end
  end

  # --- Private ---

  defp extract_dynamic_segments(path) do
    path
    |> String.split("/", trim: true)
    |> Enum.filter(&String.starts_with?(&1, ":"))
    |> Enum.map(fn ":" <> name -> String.to_atom(name) end)
  end

  defp build_function_clause({helper_name, action, path, []}) do
    quote do
      def unquote(helper_name)(unquote(action)), do: unquote(path)
    end
  end

  defp build_function_clause({helper_name, action, path, dynamic_segments}) do
    vars = Enum.map(dynamic_segments, &Macro.var(&1, nil))
    path_expr = build_path_expr(path, dynamic_segments)

    quote do
      def unquote(helper_name)(unquote(action), unquote_splicing(vars)) do
        unquote(path_expr)
      end
    end
  end

  defp build_path_expr(path, _dynamic_segments) do
    parts =
      path
      |> String.split("/", trim: true)
      |> Enum.map(fn
        ":" <> name ->
          var = Macro.var(String.to_atom(name), nil)
          quote do: to_string(unquote(var))

        static ->
          static
      end)

    Enum.reduce(parts, quote(do: ""), fn
      part, acc when is_binary(part) ->
        quote do: unquote(acc) <> "/" <> unquote(part)

      part, acc ->
        quote do: unquote(acc) <> "/" <> unquote(part)
    end)
  end
end
