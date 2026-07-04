defmodule BlogWeb.MarkdownTest do
  use ExUnit.Case, async: true

  alias BlogWeb.Markdown

  defp to_html(markdown) do
    {:safe, html} = Markdown.to_html(markdown)
    html
  end

  describe "to_html/1" do
    test "converts headings" do
      assert to_html("# Hello") =~ "<h1>Hello</h1>"
      assert to_html("## Sub") =~ "<h2>Sub</h2>"
    end

    test "converts bold and italic text" do
      html = to_html("**bold** and *italic*")
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "renders fenced code blocks with syntax highlighting" do
      html = to_html("```elixir\nIO.puts(:hello)\n```")
      assert html =~ "<pre"
      assert html =~ "language-elixir"
      assert html =~ ":hello"
    end

    test "renders inline code" do
      html = to_html("Use `IO.puts` to print")
      assert html =~ "<code>IO.puts</code>"
    end

    test "renders tables" do
      md = """
      | Name | Age |
      | --- | --- |
      | Alice | 30 |
      """

      html = to_html(md)
      assert html =~ "<table>"
      assert html =~ "<th>Name</th>"
      assert html =~ "<td>Alice</td>"
    end

    test "renders task list items" do
      html = to_html("- [ ] todo\n- [x] done")
      assert html =~ "<ul>"
      assert html =~ "todo"
      assert html =~ "done"
    end

    test "renders strikethrough text" do
      html = to_html("~~deleted~~")
      assert html =~ "<del>deleted</del>"
    end

    test "autolinks bare URLs" do
      html = to_html("Visit https://example.com for more")
      assert html =~ ~s(<a href="https://example.com")
      assert html =~ "https://example.com</a>"
    end

    test "strips script tags for XSS safety" do
      html = to_html("<script>alert('xss')</script>")
      refute html =~ "<script>"
      refute html =~ "alert"
    end

    test "returns empty HTML for nil input" do
      assert to_html(nil) == ""
    end

    test "returns empty HTML for empty string input" do
      assert to_html("") == ""
    end

    test "passes raw HTML through (unsafe: true)" do
      html = to_html("<div>Hello</div>")
      assert html =~ "<div>Hello</div>"
    end

    test "wraps output in a Phoenix.HTML raw tuple" do
      assert {:safe, _html} = Markdown.to_html("test")
    end
  end
end
