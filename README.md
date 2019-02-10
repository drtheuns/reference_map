# ReferenceMap

This package define a simple serializer to serialize a nested resource into a
map that is linked by references. The format is based on
[JSON-API](https://jsonapi.org/) but not quite the same.

## Example

The following response showcases a single ("show") resource of a typical
posts/comments/author model (post has comments; post and comments both have an
author)

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

See [`reference_map.ex`](./lib/reference_map.ex) for more information.

## Installation

This package is currently not available on hex.pm, as it's not yet production
ready. For now it can be installed by:

```
{:reference_map, git: "https://git.sr.ht/~drtheuns/reference_map", tag: "0.2.0"}
```
