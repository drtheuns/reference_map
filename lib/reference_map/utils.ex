defmodule ReferenceMap.Utils do
  @doc """
  Turn a list of path strings into a nested tree-like map.

  ## Examples

      iex> ReferenceMap.Utils.relation_paths_to_tree(["post.comments", "post.comments.author", "post.author"])
      %{post: %{comments: %{author: %{}}, author: %{}}}
  """
  def relation_paths_to_tree(paths) when is_list(paths) do
    paths
    |> Enum.map(&path_string_to_atom_list/1)
    |> Enum.reduce(%{}, fn atom_path, acc ->
      put_in(acc, Enum.map(atom_path, &Access.key(&1, %{})), %{})
    end)
  end

  @doc """
  Convert a path string into an atom list.

  ## Examples

      iex> ReferenceMap.Utils.path_string_to_atom_list("post.comments.author")
      [:post, :comments, :author]
  """
  def path_string_to_atom_list(string) do
    string
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
  end

  @doc """
  Update the map with the given `value` only if that key is `nil`.

  ## Examples

      iex> ReferenceMap.Utils.maybe_set_default(%{hello: nil}, [:hello], 5)
      %{hello: 5}

      iex> ReferenceMap.Utils.maybe_set_default(%{hello: 5}, [:hello], 6)
      %{hello: 5}
  """
  def maybe_set_default(nil, _, _), do: nil

  def maybe_set_default(map, path, value) when is_map(map) and is_list(path) do
    update_in(map, path, fn
      nil ->
        value

      current ->
        current
    end)
  end
end
