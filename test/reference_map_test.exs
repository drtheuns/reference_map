defmodule ReferenceMapTest do
  use ExUnit.Case, async: true
  doctest ReferenceMap
  doctest ReferenceMap.Utils

  defmodule Post do
    defstruct [:uuid, :title, :body, :author, :comments]
  end

  defmodule Comment do
    defstruct [:uuid, :body, :author]
  end

  defmodule Author do
    defstruct [:uuid, :name]
  end

  defmodule PostView do
    use ReferenceMap.View, id: :uuid

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

    @impl true
    def relationships(_conn) do
      %{
        comments: %RelatedView{
          view: ReferenceMapTest.CommentView,
          template: "comment.json"
        },
        author: %RelatedView{
          view: ReferenceMapTest.AuthorView,
          template: "author.json"
        }
      }
    end
  end

  defmodule CommentView do
    use ReferenceMap.View, id: :uuid

    def render("comment.json", %{data: comment}) do
      %{
        id: comment.uuid,
        type: "comment",
        attributes: %{
          body: comment.body
        }
      }
    end

    @impl true
    def relationships(_conn) do
      %{
        author: %RelatedView{
          view: ReferenceMapTest.AuthorView,
          template: "author.json"
        }
      }
    end
  end

  defmodule AuthorView do
    use ReferenceMap.View, id: :uuid

    def render("author.json", %{data: author}) do
      %{
        id: author.uuid,
        type: "author",
        attributes: %{
          name: author.name
        }
      }
    end
  end

  def post_fixture(attrs \\ %{}) do
    map =
      Enum.into(attrs, %{
        uuid: UUID.uuid4(),
        title: "Post fixture title",
        body: "Post fixture body"
      })

    struct(Post, map)
  end

  def comment_fixture(attrs \\ %{}) do
    map =
      Enum.into(attrs, %{
        uuid: UUID.uuid4(),
        body: "Comment fixture body"
      })

    struct(Comment, map)
  end

  def author_fixture(attrs \\ %{}) do
    map =
      Enum.into(attrs, %{
        uuid: UUID.uuid4(),
        name: "Author fixture name"
      })

    struct(Author, map)
  end

  @tag :positive
  test "serialize/2 should render nested resources" do
    post_author = author_fixture()
    post = post_fixture(%{author: post_author})

    expected_response = %{
      data: %{
        id: post.uuid,
        type: "post",
        attributes: %{
          title: post.title,
          body: post.body
        },
        relationships: %{
          author: post_author.uuid
        }
      },
      included: %{
        author: %{
          post_author.uuid => %{
            id: post_author.uuid,
            type: "author",
            attributes: %{
              name: post_author.name
            }
          }
        }
      }
    }

    # Emulate a render call from the controller
    data = %{
      data: post,
      conn: %{},
      view_module: PostView,
      view_template: "show.json",
      # We want the post.author to be included
      relations: ["author"]
    }

    assert ReferenceMap.serialize(data, "post.json") == expected_response
  end

  @tag :positive
  test "serialize/2 should render nested resources with lists" do
    comment_author = author_fixture()
    comment = comment_fixture(%{author: comment_author})
    post_author = author_fixture()
    post = post_fixture(%{author: post_author, comments: [comment]})

    expected_response = %{
      data: [
        %{
          id: post.uuid,
          type: "post",
          attributes: %{
            title: post.title,
            body: post.body
          },
          relationships: %{
            author: post_author.uuid,
            comments: [
              comment.uuid
            ]
          }
        }
      ],
      included: %{
        author: %{
          post_author.uuid => %{
            id: post_author.uuid,
            type: "author",
            attributes: %{
              name: post_author.name
            }
          },
          comment_author.uuid => %{
            id: comment_author.uuid,
            type: "author",
            attributes: %{
              name: comment_author.name
            }
          }
        },
        comments: %{
          comment.uuid => %{
            id: comment.uuid,
            type: "comment",
            attributes: %{
              body: comment.body
            },
            relationships: %{
              author: comment_author.uuid
            }
          }
        }
      }
    }

    # Emulate a render call from the controller
    data = %{
      data: [post],
      conn: %{},
      view_module: PostView,
      view_template: "index.json",
      # We want the post.author to be included
      relations: ["author", "comments.author"]
    }

    assert ReferenceMap.serialize(data, "post.json") == expected_response
  end

  @tag :negative
  test "serialize/2 won't crash when relation is not loaded" do
    post = post_fixture()

    expected_response = %{
      data: %{
        id: post.uuid,
        type: "post",
        attributes: %{
          title: post.title,
          body: post.body
        },
        # Since the relation was requested (but doesn't exist), it should be rendered.
        relationships: %{author: nil}
      }
    }

    # Emulate a render call from the controller
    data = %{
      data: post,
      conn: %{},
      view_module: PostView,
      view_template: "show.json",
      # We want the post.author to be included
      relations: ["author", "user"]
    }

    assert ReferenceMap.serialize(data, "post.json") == expected_response
  end
end
