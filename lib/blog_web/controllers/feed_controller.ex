defmodule BlogWeb.FeedController do
  use BlogWeb, :controller

  @feed_url "https://tlarevo.me/feed.xml"
  @site_url "https://tlarevo.me"

  def index(conn, _params) do
    posts =
      case Blog.fetch_posts(50) do
        {:ok, %{posts: posts}} -> posts
        _error -> []
      end

    xml = build_feed(posts)

    conn
    |> put_resp_content_type("application/atom+xml")
    |> send_resp(200, xml)
  end

  defp build_feed(posts) do
    updated = List.first(posts)["createdAt"] || (DateTime.utc_now() |> DateTime.to_iso8601())

    entries =
      posts
      |> Enum.map(&build_entry/1)
      |> Enum.join("\n    ")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>tlarevo.me</title>
      <link href="#{@feed_url}" rel="self" />
      <link href="#{@site_url}" />
      <updated>#{updated}</updated>
      <id>#{@site_url}</id>
      #{entries}
    </feed>
    """
  end

  defp build_entry(post) do
    number = post["number"]
    title = post["title"] || "Untitled"
    updated = post["createdAt"] || ""
    id = "#{@site_url}/posts/#{number}"

    """
    <entry>
        <title>#{xml_escape(title)}</title>
        <link href="#{@site_url}/posts/#{number}" />
        <id>#{xml_escape(id)}</id>
        <updated>#{updated}</updated>
        <summary>#{xml_escape(title)}</summary>
      </entry>
    """
  end

  defp xml_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp xml_escape(_), do: ""
end
