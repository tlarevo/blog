defmodule BlogWeb.SitemapController do
  use BlogWeb, :controller

  @site_url "https://tlarevo.me"

  def index(conn, _params) do
    posts =
      case Blog.fetch_posts(100) do
        {:ok, %{posts: posts}} -> posts
        _error -> []
      end

    xml = build_sitemap(posts)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp build_sitemap(posts) do
    static_urls = static_urls()
    post_urls = Enum.map(posts, &build_post_url/1)
    urls = Enum.join(static_urls ++ post_urls, "\n    ")

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      #{urls}
    </urlset>
    """
  end

  defp static_urls do
    [
      ~s(<url><loc>#{@site_url}/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>),
      ~s(<url><loc>#{@site_url}/posts</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>)
    ]
  end

  defp build_post_url(post) do
    number = post["number"]
    lastmod = post["createdAt"] || ""

    ~s(<url><loc>#{@site_url}/posts/#{number}</loc><lastmod>#{lastmod}</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>)
  end
end
