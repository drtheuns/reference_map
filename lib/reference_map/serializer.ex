defmodule ReferenceMap.Serializer do
  @moduledoc """
  This module contains all the logic used to serialize the resource(s) to the
  reference format. These functions will generally not be used directly. Instead,
  use the `ReferenceMap.serialize/2` function from your Phoenix View.
  """
  alias ReferenceMap.RelatedView

  @doc """
  Serializes the data in a way that can be used in a Phoenix View's `render`
  function.
  """
  def from_render(data = %{data: resource, conn: conn, view_module: view_module}, template) do
    relations =
      data
      |> Map.get(:relations, [])
      |> ReferenceMap.Utils.relation_paths_to_tree()

    context = %{
      conn: conn,
      phoenix_context: data,
      relations: relations,
      template: template,
      view: view_module
    }

    to_reference_map(resource, context)
  end

  @doc """
  Serializes the resource based on the context.
  """
  def to_reference_map(resource, context) do
    resource
    |> serialize_resource(context)
    |> maybe_add_meta(context)
  end

  defp serialize_resource(resource, context) do
    resource
    |> render_from_view(context)
    |> wrap_in_data_map()
    |> add_included_resources(resource, context)
  end

  defp render_from_view(collection, context) when is_list(collection) do
    Enum.map(collection, fn resource ->
      render_from_view(resource, put_in(context.phoenix_context.data, resource))
    end)
  end

  defp render_from_view(resource, context = %{view: view, template: template}) do
    view.render(template, context.phoenix_context)
    |> add_included_references(resource, context)
  end

  defp add_included_references(serialized, resource, context = %{relations: relations}) do
    relations
    |> Enum.reduce(serialized, fn {relation_key, _}, serialized ->
      related_view = get_related_view(relation_key, context)

      reference =
        resource
        |> Map.get(related_view.access_key)
        |> get_reference_to_resource(related_view.id)

      put_in(serialized, [Access.key(:relationships, %{}), related_view.name], reference)
    end)
  end

  defp get_reference_to_resource(nil, _id_field), do: nil

  defp get_reference_to_resource(resource, id_field) when is_list(resource) do
    Enum.map(resource, &get_reference_to_resource(&1, id_field))
  end

  defp get_reference_to_resource(resource, id_field) when is_map(resource) do
    Map.get(resource, id_field)
  end

  defp add_included_resources(serialized, collection, context) when is_list(collection) do
    Enum.reduce(collection, serialized, fn resource, acc ->
      add_included_resources(acc, resource, context)
    end)
  end

  defp add_included_resources(serialized, resource, context = %{relations: relations}) do
    relations
    |> Enum.reduce(serialized, fn {relation_key, child_includes}, serialized ->
      related_view = get_related_view(relation_key, context)

      resource = Map.get(resource, related_view.access_key)
      context = %{context | relations: child_includes}

      add_child_resource(serialized, resource, context, related_view)
    end)
  end

  defp add_child_resource(serialized, _resource = nil, _context, _related_view) do
    serialized
  end

  defp add_child_resource(serialized, collection, context, related_view)
       when is_list(collection) do
    Enum.reduce(collection, serialized, fn resource, acc ->
      add_child_resource(acc, resource, context, related_view)
    end)
  end

  defp add_child_resource(serialized, resource, context, related_view) do
    context = update_context(context, related_view, resource)
    is_rendered = rendered?(serialized, resource, related_view)

    maybe_add_include(serialized, resource, context, related_view, is_rendered)
  end

  defp maybe_add_include(serialized, _, _, _, true = _already_rendered) do
    serialized
  end

  defp maybe_add_include(serialized, resource, context, related_view, _unrendered) do
    rendered = render_from_view(resource, context)

    put_in(
      serialized,
      [
        Access.key(:included, %{}),
        Access.key(related_view.name, %{}),
        Map.get(resource, related_view.id)
      ],
      rendered
    )
    |> add_included_resources(resource, context)
  end

  defp rendered?(serialized, resource, related_view) do
    get_in(serialized, [:included, related_view.name, Map.get(resource, related_view.id)]) != nil
  end

  defp update_context(context, %RelatedView{} = related_view, resource) do
    Map.merge(context, %{
      view: related_view.view,
      template: related_view.template,
      phoenix_context: %{context.phoenix_context | data: resource}
    })
  end

  defp maybe_add_meta(serialized, %{phoenix_context: %{meta: meta}}) do
    put_in(serialized, [:meta], meta)
  end

  defp maybe_add_meta(serialized, _data) do
    serialized
  end

  defp wrap_in_data_map(serialized) do
    %{data: serialized}
  end

  defp get_related_view(key, %{view: view, conn: conn}) do
    view.relationships(conn)
    |> Map.get(key)
    |> ReferenceMap.Utils.maybe_set_default([Access.key(:access_key)], key)
    |> ReferenceMap.Utils.maybe_set_default([Access.key(:name)], key)
    |> ReferenceMap.Utils.maybe_set_default([Access.key(:id)], view.id(conn))
  end
end
