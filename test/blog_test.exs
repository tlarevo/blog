defmodule BlogTest do
  use ExUnit.Case, async: false

  test "fetch_posts returns a controlled error when GitHub token is missing" do
    previous_token = Application.get_env(:blog, :github_token)

    try do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_posts()
    after
      if is_nil(previous_token) do
        Application.delete_env(:blog, :github_token)
      else
        Application.put_env(:blog, :github_token, previous_token)
      end
    end
  end

  test "fetch_post returns a controlled error when GitHub token is missing" do
    previous_token = Application.get_env(:blog, :github_token)

    try do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_post(1)
    after
      if is_nil(previous_token) do
        Application.delete_env(:blog, :github_token)
      else
        Application.put_env(:blog, :github_token, previous_token)
      end
    end
  end

  describe "available_tags/1" do
    test "derives a sorted list of distinct tags from labels nested in fetched discussions" do
      posts = [
        %{
          "number" => 1,
          "labels" => %{"nodes" => [%{"name" => "phoenix"}, %{"name" => "elixir"}]}
        },
        %{
          "number" => 2,
          "labels" => %{"nodes" => [%{"name" => "liveview"}, %{"name" => "phoenix"}]}
        }
      ]

      assert Blog.available_tags(posts) == ["elixir", "liveview", "phoenix"]
    end

    test "deduplicates repeated labels across discussions and within one discussion" do
      posts = [
        %{"labels" => %{"nodes" => [%{"name" => "elixir"}, %{"name" => "elixir"}]}},
        %{"labels" => %{"nodes" => [%{"name" => "elixir"}]}}
      ]

      assert Blog.available_tags(posts) == ["elixir"]
    end

    test "drops empty, blank, and nil labels" do
      labels = [
        %{"name" => ""},
        %{"name" => "   "},
        %{"name" => nil},
        %{"name" => "elixir"},
        nil
      ]

      assert Blog.available_tags(labels) == ["elixir"]
    end

    test "accepts raw label entries and plain name strings" do
      assert Blog.available_tags([%{"name" => "phoenix"}, "elixir", "elixir"]) ==
               ["elixir", "phoenix"]
    end

    test "unwraps a bare labels nodes collection" do
      assert Blog.available_tags([%{"nodes" => [%{"name" => "elixir"}]}]) == ["elixir"]
    end

    test "returns an empty list when discussions carry no labels" do
      assert Blog.available_tags([%{"number" => 1, "title" => "No labels"}]) == []
      assert Blog.available_tags([]) == []
    end

    test "is deterministic regardless of label order in the fetched data" do
      labels = [%{"name" => "b"}, %{"name" => "a"}, %{"name" => "c"}]
      reversed = Enum.reverse(labels)

      assert Blog.available_tags(labels) == Blog.available_tags(reversed)
    end

    test "trims surrounding whitespace so padded duplicates collapse" do
      assert Blog.available_tags([%{"name" => " elixir "}, %{"name" => "elixir"}]) == ["elixir"]
    end

    test "derives the tag set from labels carried by fetched discussions" do
      assert {:ok, %{posts: posts}} = Blog.TestSource.fetch_posts()
      assert Blog.available_tags(posts) == ["elixir", "phoenix"]
    end
  end
end
