defmodule BlogWeb.FeedController do
  use BlogWeb, :controller

  @feed_url "https://tlarevo.me/feed.xml"
  @site_url "https://tlarevo.me"

  def index(conn, _params) do
    posts =
      case blog_source().fetch_posts(50) do
        {:ok, %{posts: posts}} -> posts
        _error -> []
      end

    xml = build_feed(posts)

    conn
    |> put_resp_content_type("application/atom+xml")
    |> send_resp(200, xml)
  end

  defp build_feed([]) do
    updated = DateTime.utc_now() |> DateTime.to_iso8601()
    build_feed_xml([], updated)
  end

  defp build_feed([first | _] = posts) do
    updated = first["createdAt"] || (DateTime.utc_now() |> DateTime.to_iso8601())
    build_feed_xml(posts, updated)
  end

  defp build_feed_xml(posts, updated) do

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
  defp blog_source, do: Application.get_env(:blog, :blog_source, Blog)

end
