defmodule ReferenceMap do
  defdelegate serialize(data, template), to: ReferenceMap.Serializer, as: :from_render
end
