defmodule BlogWeb.BlogLive.Index do
  use BlogWeb, :live_view

  @default_count 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_posts(socket)}
  end

  @impl true
  def handle_params(params, url, socket) do
    path = URI.parse(url).path || "/"
    {:noreply, socket |> assign(request_path: path) |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    %{end_cursor: cursor} = socket.assigns

    case blog_source().fetch_posts(@default_count, [:id, :number, :title, :createdAt], cursor) do
      {:ok, %{posts: new_posts, has_next_page: has_next, end_cursor: new_cursor}} ->
        {:noreply,
         socket
         |> update(:posts, &(&1 ++ new_posts))
         |> assign(has_next_page: has_next, end_cursor: new_cursor)}

      {:error, _reason} ->
        {:noreply, assign(socket, load_error: :load_more_failed)}

      _unexpected ->
        {:noreply, assign(socket, load_error: :unexpected_response)}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog Posts")
  end

  defp load_posts(socket) do
    case blog_source().fetch_posts() do
      {:ok, %{posts: posts, has_next_page: has_next, end_cursor: cursor}} ->
        assign(socket,
          posts: posts,
          has_next_page: has_next,
          end_cursor: cursor,
          load_error: nil,
          page_title: "All articles",
          meta_description: "All articles on tlarevo.me",
          request_path: "/"
        )

      {:error, reason} ->
        assign(socket,
          posts: [],
          has_next_page: false,
          end_cursor: nil,
          load_error: reason,
          page_title: "All articles"
        )

      posts when is_list(posts) ->
        assign(socket,
          posts: posts,
          has_next_page: false,
          end_cursor: nil,
          load_error: nil,
          page_title: "All articles"
        )

      _unexpected ->
        assign(socket,
          posts: [],
          has_next_page: false,
          end_cursor: nil,
          load_error: :unexpected_response,
          page_title: "All articles"
        )
    end
  end

  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)
end
