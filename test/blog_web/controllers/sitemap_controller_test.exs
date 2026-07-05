defmodule BlogWeb.SitemapControllerTest do
  use BlogWeb.ConnCase, async: true

  test "GET /sitemap.xml returns 200 with xml content type", %{conn: conn} do
    conn = get(conn, "/sitemap.xml")
    [content_type] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "application/xml"
  end

  test "GET /sitemap.xml returns valid XML with <urlset> root", %{conn: conn} do
    conn = get(conn, "/sitemap.xml")
    assert conn.resp_body =~ "<urlset"
    assert conn.resp_body =~ "</urlset>"
  end

  test "GET /sitemap.xml contains static URLs for / and /posts", %{conn: conn} do
    conn = get(conn, "/sitemap.xml")
    assert conn.resp_body =~ "https://tlarevo.me/"
    assert conn.resp_body =~ "https://tlarevo.me/posts</loc>"
  end

  test "GET /sitemap.xml contains post URLs", %{conn: conn} do
    conn = get(conn, "/sitemap.xml")
    assert conn.resp_body =~ "https://tlarevo.me/posts/1"
    assert conn.resp_body =~ "https://tlarevo.me/posts/2"
  end
end
