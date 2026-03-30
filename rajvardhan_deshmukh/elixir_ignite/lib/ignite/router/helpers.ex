defmodule Ignite.Router.Helpers do
  @moduledoc """
  Generates path helper functions from route metadata.
  """

  @doc """
  Builds an AST of helper functions from a list of route info tuples.
  `route_info` is expected to be a list of:
  `{method, path, _controller, action}`
  """
  def build_helper_functions(route_info) do
    # Group by the derived function name (e.g., :user_path)
    # Then generate one function clause per action.
    
    # We use a map to deduplicate, because PUT and PATCH might map to the same path and action (:update)
    clauses_by_name =
      Enum.reduce(route_info, %{}, fn {_method, path, _controller, action}, acc ->
        name = derive_name(path)
        clause = build_clause(name, action, path)
        
        # Deduplicate identical clauses (like PUT and PATCH forming the same update clause)
        clauses = Map.get(acc, name, [])
        
        # Simple macro clause comparison won't work perfectly due to context in AST,
        # but since we generate them deterministically based on action and path, 
        # we can deduplicate by {action, path}.
        key = {action, path}
        
        if Enum.any?(Map.get(acc, {:keys, name}, []), &(&1 == key)) do
          acc
        else
          keys = [key | Map.get(acc, {:keys, name}, [])]
          acc
          |> Map.put({:keys, name}, keys)
          |> Map.put(name, clauses ++ [clause])
        end
      end)
      
    # Extract just the AST clauses
    Enum.flat_map(clauses_by_name, fn
      {{:keys, _name}, _keys} -> []
      {_name, clauses} -> clauses
    end)
  end

  # Builds a single function clause AST
  # e.g. def user_path(:show, id), do: "/users/" <> to_string(id)
  defp build_clause(name, action, path) do
    segments = String.split(path, "/", trim: true)
    
    # Determine the dynamic parameters from the path
    params = 
      segments
      |> Enum.filter(&String.starts_with?(&1, ":"))
      |> Enum.map(fn param ->
        var_name = String.slice(param, 1..-1//1) |> String.to_atom()
        Macro.var(var_name, nil)
      end)

    # Build the path construction AST
    # ["/users/", id, "/posts/", post_id]
    path_expr = build_path_expr(segments)

    if params == [] do
      quote do
        def unquote(name)(unquote(action)) do
          unquote(path_expr)
        end
      end
    else
      # We just take the first param for now, or we can take a generic list of params.
      # Phoenix allows passing multiple arguments directly or via a struct.
      # For our simple framework tutorial, we expand them as individual arguments:
      # def user_post_path(:show, user_id, id)
      
      quote do
        def unquote(name)(unquote(action), unquote_splicing(params)) do
          unquote(path_expr)
        end
      end
    end
  end

  defp build_path_expr(segments) do
    if segments == [] do
      "/"
    else
      segments
      |> Enum.map(fn segment ->
        if String.starts_with?(segment, ":") do
          var_name = String.slice(segment, 1..-1//1) |> String.to_atom()
          var_ast = Macro.var(var_name, nil)
          quote do: to_string(unquote(var_ast))
        else
          "/" <> segment
        end
      end)
      |> Enum.reduce(fn r, l -> quote(do: unquote(l) <> unquote(r)) end)
    end
  end

  @doc """
  Derives a helper function name from a string path.
  """
  def derive_name(path) do
    if path == "/" do
      :root_path
    else
      segments = String.split(path, "/", trim: true)
      
      static_segments = Enum.reject(segments, &String.starts_with?(&1, ":"))
      
      if static_segments == [] do
        :root_path
      else
        static_segments
        |> List.update_at(-1, &naive_singularize/1)
        |> Enum.join("_")
        |> String.replace("-", "_")
        |> Kernel.<>("_path")
        |> String.to_atom()
      end
    end
  end

  @doc """
  Naively singularizes standard English nouns used in APIs.
  """
  def naive_singularize(word) do
    cond do
      Regex.match?(~r/(ss|sh|ch|x|z)es$/, word) ->
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
end
