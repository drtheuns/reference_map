defmodule ReferenceMap.RelatedView do
  @enforce_keys [:view, :template]

  defstruct [:view, :template, :name, :access_key]

  @typedoc """
  The type to use when specifying relationships inside the `relationships/1`
  function in your views. The following options are supported:

  * `:view`: The module to use when rendering objects of this type.
  * `:template`: The template name (e.g. `post.json`) to use when rendering a
    single object of the related type.
  * `:name`: The name to use for the output of this relationship. Defaults to
    the relationship name.
  * `:access_key`: The key that should be used to get this relationship from the
    parent resource. This allows the relationship name to differ from the actual
    foreign key.
  """
  @type t :: %__MODULE__{
          view: atom(),
          template: String.t(),
          name: atom(),
          access_key: atom()
        }
end
