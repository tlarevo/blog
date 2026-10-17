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

  test "index renders a retro tag chip row above the post list", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "tag-chips"
    assert html =~ "tag-chip"

    {chip_row_pos, _} = :binary.match(html, "tag-chips")
    {post_list_pos, _} = :binary.match(html, ~s(<ul class="posts">))

    assert chip_row_pos < post_list_pos
  end

  test "tag chips have an active selected state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ~s(.tag-chip-selected[phx-value-tag="All"]))
    assert has_element?(view, ~s(.tag-chip[phx-value-tag="elixir"]))

    view |> element(~s(.tag-chip[phx-value-tag="elixir"])) |> render_click()

    assert has_element?(view, ~s(.tag-chip-selected[phx-value-tag="elixir"]))
    refute has_element?(view, ~s(.tag-chip-selected[phx-value-tag="All"]))
    assert render(view) =~ ~s(aria-pressed="true")
  end

  test "selecting a tag chip shows only posts carrying that label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert render(view) =~ "Shipping Phoenix without fear"
    assert render(view) =~ "A tiny note on LiveView"

    view |> element(~s(.tag-chip[phx-value-tag="phoenix"])) |> render_click()

    html = render(view)
    assert html =~ "Shipping Phoenix without fear"
    refute html =~ "A tiny note on LiveView"
  end

  test "selecting a shared label keeps every post carrying it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element(~s(.tag-chip[phx-value-tag="elixir"])) |> render_click()

    html = render(view)
    assert html =~ "Shipping Phoenix without fear"
    assert html =~ "A tiny note on LiveView"
  end

  test "deselecting the active tag restores the unfiltered list", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element(~s(.tag-chip[phx-value-tag="liveview"])) |> render_click()
    refute render(view) =~ "Shipping Phoenix without fear"

    view |> element(~s(.tag-chip[phx-value-tag="liveview"])) |> render_click()

    html = render(view)
    assert html =~ "Shipping Phoenix without fear"
    assert html =~ "A tiny note on LiveView"
  end

  test "clicking the All chip clears the active filter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element(~s(.tag-chip[phx-value-tag="phoenix"])) |> render_click()
    refute render(view) =~ "A tiny note on LiveView"

    view |> element(~s(.tag-chip[phx-value-tag="All"])) |> render_click()

    assert has_element?(view, ~s(.tag-chip-selected[phx-value-tag="All"]))
    assert render(view) =~ "Shipping Phoenix without fear"
    assert render(view) =~ "A tiny note on LiveView"
  end

  test "GET /posts/:number renders sanitized Markdown", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/posts/1")

    assert html =~ "Shipping Phoenix without fear"
    assert html =~ "Posted on May 20, 2026"
    assert html =~ "min read"
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
