defmodule BlogWeb.BlogLive.Show do
  use BlogWeb, :live_view

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    {:ok, load_post(socket, number)}
  end

  defp load_post(socket, number) do
    case blog_source().fetch_post(number) do
      {:ok, post} ->
        assign(socket,
          post: post,
          load_error: nil,
          page_title: post["title"] || "Post",
          reading_time: BlogWeb.BlogLive.Helpers.reading_time(post["body"]),
          meta_description: BlogWeb.BlogLive.Helpers.strip_markdown(post["body"]),
          og_type: "article",
          request_path: "/posts/#{number}"
        )

      {:error, reason} ->
        assign(socket, post: nil, load_error: reason, page_title: "Post unavailable")

      post when is_map(post) ->
        assign(socket,
          post: post,
          load_error: nil,
          page_title: post["title"] || "Post",
          reading_time: BlogWeb.BlogLive.Helpers.reading_time(post["body"]),
          meta_description: BlogWeb.BlogLive.Helpers.strip_markdown(post["body"]),
          og_type: "article",
          request_path: "/posts/#{number}"
        )

      _unexpected ->
        assign(socket,
          post: nil,
          load_error: :unexpected_response,
          page_title: "Post unavailable"
        )
    end
  end

  def json_ld(post) do
    json =
      %{
        "@context" => "https://schema.org",
        "@type" => "BlogPosting",
        "headline" => post["title"],
        "datePublished" => post["createdAt"],
        "author" => %{
          "@type" => "Person",
          "name" => "Tharindu Abeydeera",
          "url" => "https://github.com/tlarevo"
        },
        "publisher" => %{
          "@type" => "Person",
          "name" => "Tharindu Abeydeera"
        },
        "url" => "https://tlarevo.me/posts/#{post["number"]}"
      }
      |> Jason.encode!()
      |> String.replace(~r{</script>}i, "<\\/script>")

    Phoenix.HTML.raw(json)
  end

  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)
end
