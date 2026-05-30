defmodule BlogWeb.BlogLive.Show do
  use BlogWeb, :live_view

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    {:ok, load_post(socket, number)}
  end

  defp load_post(socket, number) do
    case blog_source().fetch_post(number) do
      {:ok, post} ->
        assign(socket, post: post, load_error: nil, page_title: post["title"])

      {:error, reason} ->
        assign(socket, post: nil, load_error: reason, page_title: "Post unavailable")

      post when is_map(post) ->
        assign(socket, post: post, load_error: nil, page_title: post["title"])

      _unexpected ->
        assign(socket,
          post: nil,
          load_error: :unexpected_response,
          page_title: "Post unavailable"
        )
    end
  end

  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)
end
