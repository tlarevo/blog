defmodule BlogWeb.BlogLive.Index do
  use BlogWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_posts(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog Posts")
  end

  defp load_posts(socket) do
    case blog_source().fetch_posts() do
      {:ok, posts} ->
        assign(socket, posts: posts, load_error: nil, page_title: "All articles")

      {:error, reason} ->
        assign(socket, posts: [], load_error: reason, page_title: "All articles")

      posts when is_list(posts) ->
        assign(socket, posts: posts, load_error: nil, page_title: "All articles")

      _unexpected ->
        assign(socket, posts: [], load_error: :unexpected_response, page_title: "All articles")
    end
  end

  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)
end
