defmodule Blog.TestSource do
  @moduledoc false

  @posts [
    %{
      "id" => "discussion-1",
      "number" => 1,
      "title" => "Shipping Phoenix without fear",
      "createdAt" => "2026-05-20T09:30:00Z",
      "labels" => %{"nodes" => [%{"name" => "phoenix"}, %{"name" => "elixir"}]},
      "tags" => ["phoenix", "elixir"]
    },
    %{
      "id" => "discussion-2",
      "number" => 2,
      "title" => "A tiny note on LiveView",
      "createdAt" => "2026-05-18T14:45:00Z",
      "labels" => %{"nodes" => [%{"name" => "elixir"}, %{"name" => ""}]},
      "tags" => ["liveview", "elixir"]
    },
    %{
      "id" => "discussion-3",
      "number" => 3,
      "title" => "Plugs and pipelines in Phoenix",
      "createdAt" => "2026-05-15T09:30:00Z",
      "labels" => %{"nodes" => [%{"name" => "phoenix"}]},
      "tags" => ["phoenix"]
    },
    %{
      "id" => "discussion-4",
      "number" => 4,
      "title" => "LiveView streams in practice",
      "createdAt" => "2026-05-12T09:30:00Z",
      "labels" => %{"nodes" => [%{"name" => "liveview"}]},
      "tags" => ["liveview"]
    },
    %{
      "id" => "discussion-5",
      "number" => 5,
      "title" => "OTP supervision trees",
      "createdAt" => "2026-05-08T09:30:00Z",
      "labels" => %{"nodes" => [%{"name" => "elixir"}]},
      "tags" => ["elixir"]
    },
    %{
      "id" => "discussion-6",
      "number" => 6,
      "title" => "Query composition in Ecto",
      "createdAt" => "2026-05-05T09:30:00Z",
      "labels" => %{"nodes" => [%{"name" => "elixir"}, %{"name" => "ecto"}]},
      "tags" => ["elixir", "ecto"]
    }
  ]

  # Serves @posts in fixed two-post pages keyed by the `after` cursor, so
  # tests can drive the "Load more" pagination without touching the network.
  @page_size 2

  @post %{
    "id" => "discussion-1",
    "number" => 1,
    "title" => "Shipping Phoenix without fear",
    "createdAt" => "2026-05-20T09:30:00Z",
    "body" => """
    This post has **strong text** and a [safe link](https://example.com).

    <script>alert("owned")</script>
    """
  }

  def fetch_posts(_count \\ 10, _attr \\ [:id, :number, :title, :createdAt], after_cursor \\ nil) do
    start = cursor_offset(after_cursor)
    page = Enum.slice(@posts, start, @page_size)
    next_offset = start + @page_size
    has_next_page = next_offset < length(@posts)

    {:ok,
     %{
       posts: page,
       has_next_page: has_next_page,
       end_cursor: if(has_next_page, do: "cursor-#{next_offset}", else: nil)
     }}
  end

  def fetch_post(number) when number in [1, "1"], do: {:ok, @post}
  def fetch_post(_number), do: {:error, :not_found}

  defp cursor_offset(nil), do: 0

  defp cursor_offset("cursor-" <> offset) do
    case Integer.parse(offset) do
      {parsed, ""} -> parsed
      _invalid -> 0
    end
  end

  defp cursor_offset(_other), do: 0
end
