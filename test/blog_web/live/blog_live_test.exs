defmodule BlogWeb.BlogLiveTest do
  use BlogWeb.ConnCase, async: true

  test "GET / renders the Archie-styled post index", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "All articles"
    assert html =~ "Shipping Phoenix without fear"
    assert html =~ "A tiny note on LiveView"
    assert html =~ ~s(href="/posts/1")
    assert html =~ "May 20, 2026"
  end

  test "GET /posts renders the post index alias", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/posts")

    assert html =~ "All articles"
    assert html =~ "Shipping Phoenix without fear"
  end

  test "GET /posts/:number renders sanitized Markdown", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/posts/1")

    assert html =~ "Shipping Phoenix without fear"
    assert html =~ "Posted on May 20, 2026"
    assert html =~ "<strong>strong text</strong>"
    assert html =~ ~s(href="https://example.com")
    assert html =~ "safe link"
    refute html =~ "<script>"
    refute html =~ "owned"
  end

  test "GET /posts/:number renders a graceful unavailable state", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/posts/404")

    assert html =~ "Post unavailable"
    assert html =~ "The post could not be loaded."
  end
end
