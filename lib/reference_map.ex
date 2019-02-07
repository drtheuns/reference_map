defmodule ReferenceMap do
  @doc """
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

  First you need to create your resources. These can be plain maps or structs.
  These will likely be the structs used by Ecto.

  Next, define your view module(s):

  ```elixir
  defmodule PostView do
    def render("show.json", data) do
      ReferenceMap.serialize(data, "post.json")
    end

    def render("post.json", %{data: post}) do
      %{
        id: post.uuid,
        type: "post",
        attributes: %{
          title: post.title,
          body: post.body
        }
      }
    end

    def relationships(_conn) do
      %{
        comments: %ReferenceMap.RelatedView{
          view: CommentView,
          template: "comment.json"
        },
        author: %ReferenceMap.RelatedView{
          view: AuthorView,
          template: "author.json"
        }
      }
    end

    def id(_conn), do: :uuid
  end
  ```
  For a full example, see the `ReferenceMapTest`.
  """

  defdelegate serialize(data, template), to: ReferenceMap.Serializer, as: :from_render
end
