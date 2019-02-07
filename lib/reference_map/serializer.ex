defmodule ReferenceMap.Serializer do
  @moduledoc """
  This module defines the rendering functions to use in order to generate a standard API.

  The resulting JSON is based on the [jsonapi](https://jsonapi.org) standard, but deviates
  a little by being more opinionated. For example: *all* related resources go into the
  `included` object. These objects are keyed by the id to simplify lookup, and only a
  reference is set from the parent model to this included object.

  ## Example response

  The following response showcases a single ("show") resource of a typical
  posts/comments/author model (post has comments; post and comments both have an author)

  ```elixir
    %{
      data: %{
        id: "141abc66-4e11-4e95-a935-3b5f73f94c5c",
        type: "post",
        attributes: %{
          title: "How to render",
          body: "..."
        },
        relationships: %{
          author: "f21c6f7e-068b-4cd2-a4de-289cf4fffce9",
          comment: [
            "83acb0b1-2a5f-4b13-959b-4ddcfc1d4006"
          ]
        }
      },
      included: %{
        author: %{
          "f21c6f7e-068b-4cd2-a4de-289cf4fffce9": %{
            id: "f21c6f7e-068b-4cd2-a4de-289cf4fffce9",
            type: "author",
            attributes: %{
              name: "John Doe",
            }
          },
          "b702b345-1e15-4e17-a47f-b514f20b1799": %{
            id: "b702b345-1e15-4e17-a47f-b514f20b1799",
            type: "author",
            attributes: %{
              name: "Jane Doe"
            }
          }
        },
        comment: %{
          "83acb0b1-2a5f-4b13-959b-4ddcfc1d4006": %{
            id: "83acb0b1-2a5f-4b13-959b-4ddcfc1d4006",
            type: "comment",
            attributes: %{
              body: "..."
            },
            relationships: %{
              author: "b702b345-1e15-4e17-a47f-b514f20b1799"
            }
          }
        }
      }
    }
  ```

  ## Usage

  TODO (example view, config methods, etc)
  """
  alias ReferenceMap.RelatedView

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

  # resource, conn, view, template, relations
  def to_reference_map(resource, context) do
    resource
    |> serialize_resource(context)
    |> maybe_add_meta(context)
    |> IO.inspect()
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

  defp add_child_resource(serialized, collection, context, related_view)
       when is_list(collection) do
    Enum.reduce(collection, serialized, fn resource, acc ->
      add_child_resource(acc, resource, context, related_view)
    end)
  end

  defp add_child_resource(serialized, resource, context, related_view) do
    context =
      context
      |> update_context(related_view)
      |> Map.put(:phoenix_context, %{context.phoenix_context | data: resource})

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

  defp update_context(context, %RelatedView{} = related_view) do
    Map.merge(context, %{
      view: related_view.view,
      template: related_view.template
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
    |> Map.put(:id, view.id(conn))
  end
end
