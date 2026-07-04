defmodule Blog.BlogTest do
  @moduledoc """
  Unit tests for the Blog module.

  Each test starts a local mock HTTP server (Blog.GraphQLMock) on a random port,
  configures Blog to use it via Application env, and tears everything down on exit.
  """
  use ExUnit.Case, async: false

  alias Blog.GraphQLMock

  # ── Shared test data ────────────────────────────────────────

  @posts_response %{
    "data" => %{
      "repository" => %{
        "discussions" => %{
          "nodes" => [
            %{
              "id" => "D_1",
              "number" => 1,
              "title" => "First Post",
              "createdAt" => "2026-01-01T00:00:00Z"
            },
            %{
              "id" => "D_2",
              "number" => 2,
              "title" => "Second Post",
              "createdAt" => "2025-12-31T00:00:00Z"
            }
          ],
          "pageInfo" => %{
            "hasNextPage" => true,
            "endCursor" => "cursor_abc"
          }
        }
      }
    }
  }

  @post_response %{
    "data" => %{
      "repository" => %{
        "discussion" => %{
          "id" => "D_1",
          "number" => 1,
          "title" => "First Post",
          "body" => "Hello **world**",
          "createdAt" => "2026-01-01T00:00:00Z",
          "comments" => %{
            "totalCount" => 1,
            "nodes" => [
              %{
                "id" => "C_1",
                "body" => "Nice post!",
                "createdAt" => "2026-01-02T00:00:00Z",
                "updatedAt" => "2026-01-02T00:00:00Z"
              }
            ]
          }
        }
      }
    }
  }

  @not_found_response %{
    "data" => %{
      "repository" => %{
        "discussion" => nil
      }
    }
  }

  @graphql_error_response %{
    "errors" => [%{"message" => "Something went wrong"}]
  }

  # ── Setup / Teardown ────────────────────────────────────────

  setup do
    # Ensure a fresh cache GenServer + ETS table for isolation.
    # Blog.Cache is started by the application supervision tree, so it
    # should already be running. If not (e.g. after a cross-file stop), start it.
    unless Process.whereis(Blog.Cache) do
      {:ok, _} = Blog.Cache.start_link()
    end

    # Clear any stale entries from prior tests.
    case :ets.whereis(:blog_cache) do
      table when is_reference(table) ->
        :ets.delete_all_objects(table)

      # Table was deleted by another test — recreate it directly.
      _ ->
        :ets.new(:blog_cache, [:named_table, :public, read_concurrency: true])
    end

    saved_token = Application.get_env(:blog, :github_token)
    saved_url = Application.get_env(:blog, :github_url)
    saved_mock = Application.get_env(:blog, :mock_handler)

    Application.put_env(:blog, :github_token, "test-token-12345")

    {name, port} = GraphQLMock.start()
    Application.put_env(:blog, :github_url, "http://127.0.0.1:#{port}")

    on_exit(fn ->
      GraphQLMock.stop(name)
      restore_env(:github_token, saved_token)
      restore_env(:github_url, saved_url)
      restore_env(:mock_handler, saved_mock)
    end)

    :ok
  end

  # ── fetch_posts/3 — success paths ──────────────────────────

  describe "fetch_posts/3 success" do
    test "returns paginated posts with pageInfo" do
      set_handler(fn _body ->
        {200, Jason.encode!(@posts_response)}
      end)

      assert {:ok, result} = Blog.fetch_posts()
      assert %{posts: posts, has_next_page: has_next, end_cursor: cursor} = result

      assert length(posts) == 2
      assert has_next == true
      assert cursor == "cursor_abc"

      first = hd(posts)
      assert first["id"] == "D_1"
      assert first["number"] == 1
      assert first["title"] == "First Post"
    end

    test "passes count and cursor arguments through to the query" do
      set_handler(fn body ->
        decoded = Jason.decode!(body)
        query = decoded["query"]
        # Cognac generates compact GraphQL: "discussions(first:5,...)"
        assert query =~ "discussions(first:5"
        assert query =~ "after:\"some_cursor\""
        {200, Jason.encode!(@posts_response)}
      end)

      assert {:ok, _} = Blog.fetch_posts(5, [:id, :title], "some_cursor")
    end
  end

  # ── fetch_posts/3 — error paths ────────────────────────────

  describe "fetch_posts/3 errors" do
    test "returns error when GitHub token is missing" do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_posts()
    end

    test "returns error on HTTP 500" do
      set_handler(fn _body ->
        # Req's decode_body step requires valid JSON even for error status codes
        {500, Jason.encode!(%{"message" => "Internal Server Error"})}
      end)

      assert {:error, :github_request_failed} = Blog.fetch_posts()
    end

    test "returns error on GraphQL errors in response" do
      set_handler(fn _body ->
        {200, Jason.encode!(@graphql_error_response)}
      end)

      assert {:error, :github_graphql_error} = Blog.fetch_posts()
    end

    test "returns error on malformed/unexpected response shape" do
      set_handler(fn _body ->
        {200, Jason.encode!(%{"unexpected" => "shape"})}
      end)

      assert {:error, :unexpected_github_response} = Blog.fetch_posts()
    end
  end

  # ── fetch_post/1 — success paths ───────────────────────────

  describe "fetch_post/1 success" do
    test "returns a single post with body and comments" do
      set_handler(fn _body ->
        {200, Jason.encode!(@post_response)}
      end)

      assert {:ok, post} = Blog.fetch_post(1)

      assert post["id"] == "D_1"
      assert post["number"] == 1
      assert post["title"] == "First Post"
      assert post["body"] == "Hello **world**"
      assert post["comments"]["totalCount"] == 1
    end

    test "accepts string discussion numbers" do
      set_handler(fn body ->
        decoded = Jason.decode!(body)
        query = decoded["query"]
        assert query =~ "number:42"
        {200, Jason.encode!(@post_response)}
      end)

      assert {:ok, _} = Blog.fetch_post("42")
    end
  end

  # ── fetch_post/1 — error paths ─────────────────────────────

  describe "fetch_post/1 errors" do
    test "returns error when GitHub token is missing" do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_post(1)
    end

    test "returns error for invalid discussion number" do
      assert {:error, :invalid_discussion_number} = Blog.fetch_post("not-a-number")
    end

    test "returns error when discussion is not found" do
      set_handler(fn _body ->
        {200, Jason.encode!(@not_found_response)}
      end)

      assert {:error, :not_found} = Blog.fetch_post(999)
    end
  end

  # ── Caching ─────────────────────────────────────────────────

  describe "caching" do
    test "second call returns cached result without hitting server" do
      call_count = :counters.new(1, [:atomics])

      set_handler(fn _body ->
        :counters.add(call_count, 1, 1)
        {200, Jason.encode!(@posts_response)}
      end)

      assert {:ok, first} = Blog.fetch_posts()
      assert {:ok, second} = Blog.fetch_posts()

      assert first == second
      assert :counters.get(call_count, 1) == 1
    end

    test "cache is separate for different arguments" do
      call_count = :counters.new(1, [:atomics])

      set_handler(fn _body ->
        :counters.add(call_count, 1, 1)
        {200, Jason.encode!(@posts_response)}
      end)

      assert {:ok, _} = Blog.fetch_posts(10)
      assert {:ok, _} = Blog.fetch_posts(5)

      # Both calls hit the server because cache keys differ
      assert :counters.get(call_count, 1) == 2
    end

    test "fetch_post results are cached separately from fetch_posts" do
      posts_count = :counters.new(1, [:atomics])
      post_count = :counters.new(1, [:atomics])

      set_handler(fn body ->
        decoded = Jason.decode!(body)
        query = decoded["query"]

        if String.contains?(query, "discussions(") do
          :counters.add(posts_count, 1, 1)
          {200, Jason.encode!(@posts_response)}
        else
          :counters.add(post_count, 1, 1)
          {200, Jason.encode!(@post_response)}
        end
      end)

      assert {:ok, _} = Blog.fetch_posts()
      assert {:ok, _} = Blog.fetch_post(1)

      # Each path hit server once
      assert :counters.get(posts_count, 1) == 1
      assert :counters.get(post_count, 1) == 1

      # Cached calls don't hit server again
      assert {:ok, _} = Blog.fetch_posts()
      assert {:ok, _} = Blog.fetch_post(1)

      assert :counters.get(posts_count, 1) == 1
      assert :counters.get(post_count, 1) == 1
    end
  end

  # ── Retry ───────────────────────────────────────────────────

  describe "retry on transient failure" do
    test "succeeds after transient failures" do
      handler =
        GraphQLMock.retry_handler(
          2,
          500,
          %{"error" => "transient"},
          @posts_response
        )

      set_handler(handler)

      assert {:ok, result} = Blog.fetch_posts()
      assert %{posts: [_ | _]} = result
    end

    test "exhausts retries and returns error after max attempts" do
      handler =
        GraphQLMock.retry_handler(
          10,
          500,
          %{"error" => "persistent"},
          @posts_response
        )

      set_handler(handler)

      assert {:error, _reason} = Blog.fetch_posts()
    end

    test "does not retry on missing token" do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_post(1)
    end
  end


  defp set_handler(handler) do
    Application.put_env(:blog, :mock_handler, handler)
  end

  defp restore_env(key, nil), do: Application.delete_env(:blog, key)
  defp restore_env(key, value), do: Application.put_env(:blog, key, value)
end
