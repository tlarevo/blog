defmodule BlogWeb.BlogLive.Index do
  @moduledoc """
  Post index with a tag-chip filter above the list.

  Active-filter policy (chosen explicitly):

    * There is at most one active filter. `active_tag` holds either a tag name
      or the `"All"` sentinel, which means "no filter" and is the initial state.
    * Clicking a chip selects its tag; clicking the selected chip again (or the
      "All" chip) deselects and restores the unfiltered list.
    * "Load more" keeps its cursor pagination and page size, but appends only
      the posts of each fetched page that match the active tag; with the "All"
      sentinel the whole page is appended, exactly as before the filter
      existed. Non-matching posts are not appended at all, so they do not
      reappear when the filter is later cleared.
    * Filter state lives in the LiveView process only: it resets to `"All"` on
      a fresh mount and is not persisted in the URL.

  Filtering (the visible list and the "Load more" appends alike) runs over
  already-fetched posts in the LiveView layer, so the underlying fetch and ETS
  cache behaviour is untouched.
  """

  use BlogWeb, :live_view

  alias BlogWeb.BlogLive.Helpers

  @all_tag "All"
  @default_count 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_posts(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    %{end_cursor: cursor, active_tag: active_tag} = socket.assigns

    case blog_source().fetch_posts(@default_count, [:id, :number, :title, :createdAt], cursor) do
      {:ok, %{posts: new_posts, has_next_page: has_next, end_cursor: new_cursor}} ->
        matching_posts = Helpers.filter_by_tag(new_posts, active_tag)

        {:noreply,
         socket
         |> update(:posts, &(&1 ++ matching_posts))
         |> assign(has_next_page: has_next, end_cursor: new_cursor)
         |> refresh_derived()}

      {:error, _reason} ->
        {:noreply, assign(socket, load_error: :load_more_failed)}

      _unexpected ->
        {:noreply, assign(socket, load_error: :unexpected_response)}
    end
  end

  def handle_event("select-tag", %{"tag" => tag}, socket) do
    {:noreply,
     socket
     |> assign(active_tag: toggle_tag(socket.assigns.active_tag, tag))
     |> refresh_derived()}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog Posts")
  end

  defp load_posts(socket) do
    socket =
      case blog_source().fetch_posts() do
        {:ok, %{posts: posts, has_next_page: has_next, end_cursor: cursor}} ->
          assign(socket,
            posts: posts,
            has_next_page: has_next,
            end_cursor: cursor,
            load_error: nil,
            page_title: "All articles"
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

    socket
    |> assign(active_tag: @all_tag)
    |> refresh_derived()
  end

  defp toggle_tag(current, current), do: @all_tag
  defp toggle_tag(_current, selected), do: selected

  defp refresh_derived(socket) do
    %{posts: posts, active_tag: active_tag} = socket.assigns

    assign(socket,
      tags: Helpers.tag_names(posts),
      visible_posts: Helpers.filter_by_tag(posts, active_tag)
    )
  end

  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)
end
