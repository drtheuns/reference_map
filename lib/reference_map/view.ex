defmodule ReferenceMap.View do
  @type relation_map :: %{atom() => ReferenceMap.RelatedView.t()}
  @type access_key :: atom()

  @doc """
  Defines the map of relations that could be rendered from this view.

  The `conn` object is passed in case you want to add conditional logic based on some assigns.
  """
  @callback relationships(Plug.Conn.t()) :: relation_map

  @doc """
  Defines the id key to use when rendering a reference to a resource of this view.

  Another view can alternatively define the `id` key in the `relationships` callback which
  will then be used when rendering a reference to that resource.
  """
  @callback id(Plug.Conn.t()) :: access_key()

  # TODO: docs
  defmacro __using__(opts) do
    {id_key, _opts} = Keyword.pop(opts, :id, :id)

    quote do
      @behaviour ReferenceMap.View

      alias ReferenceMap.RelatedView

      def relationships(_conn), do: %{}
      def id(_conn), do: unquote(id_key)

      defoverridable relationships: 1,
                     id: 1
    end
  end
end
