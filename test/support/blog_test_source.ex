defmodule Blog.TestSource do
  @moduledoc false

  @posts [
    %{
      "id" => "discussion-1",
      "number" => 1,
      "title" => "Shipping Phoenix without fear",
      "createdAt" => "2026-05-20T09:30:00Z"
    },
    %{
      "id" => "discussion-2",
      "number" => 2,
      "title" => "A tiny note on LiveView",
      "createdAt" => "2026-05-18T14:45:00Z"
    }
  ]

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

  def fetch_posts, do: {:ok, @posts}

  def fetch_post(number) when number in [1, "1"], do: {:ok, @post}
  def fetch_post(_number), do: {:error, :not_found}
end
