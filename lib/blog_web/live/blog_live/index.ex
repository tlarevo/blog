defmodule BlogWeb.BlogLive.Index do
  use BlogWeb, :live_view
  alias Blog

  @impl true
  def mount(_params, _session, socket) do
    posts = Blog.fetch_posts()
    {:ok, assign(socket, posts: posts, page_title: "Archie")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Blog Posts")
  end
end
