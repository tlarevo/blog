defmodule BlogWeb.FeedControllerTest do
  use BlogWeb.ConnCase, async: true

  test "GET /feed.xml returns 200 with atom+xml content type", %{conn: conn} do
    conn = get(conn, "/feed.xml")
    [content_type] = Plug.Conn.get_resp_header(conn, "content-type")
    assert content_type =~ "application/atom+xml"
  end

  test "GET /feed.xml returns valid XML with <feed> root", %{conn: conn} do
    conn = get(conn, "/feed.xml")
    assert conn.resp_body =~ "<feed"
    assert conn.resp_body =~ "</feed>"
  end

  test "GET /feed.xml contains <entry> elements for each post", %{conn: conn} do
    conn = get(conn, "/feed.xml")
    assert conn.resp_body =~ "<entry>"
    assert conn.resp_body =~ "</entry>"
    # Blog.TestSource returns 2 posts
    assert conn.resp_body =~ "Shipping Phoenix without fear"
    assert conn.resp_body =~ "A tiny note on LiveView"
  end

  test "GET /feed.xml contains site title tlarevo.me", %{conn: conn} do
    conn = get(conn, "/feed.xml")
    assert conn.resp_body =~ "<title>tlarevo.me</title>"
  end
end
