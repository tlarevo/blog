defmodule BlogWeb.BlogLive.HelpersTest do
  use ExUnit.Case, async: true

  alias BlogWeb.BlogLive.Helpers

  describe "reading_time/1" do
    test "returns nil for nil body" do
      assert Helpers.reading_time(nil) == nil
    end

    test "returns at least 1 minute for a short body" do
      assert Helpers.reading_time("just a few words") == 1
    end

    test "rounds up partial minutes" do
      # 201 words at 200 wpm rounds up to 2 minutes
      body = Enum.map_join(1..201, " ", &Integer.to_string/1)
      assert Helpers.reading_time(body) == 2
    end

    test "computes whole minutes from word count" do
      # 600 words at 200 wpm is exactly 3 minutes
      body = Enum.map_join(1..600, " ", &Integer.to_string/1)
      assert Helpers.reading_time(body) == 3
    end
  end

  describe "strip_markdown/1" do
    test "returns nil for nil" do
      assert Helpers.strip_markdown(nil) == nil
    end

    test "strips headings" do
      assert Helpers.strip_markdown("# Hello") == "Hello"
    end

    test "strips bold and italic" do
      assert Helpers.strip_markdown("**bold** and *italic*") == "bold and italic"
    end

    test "extracts link text" do
      assert Helpers.strip_markdown("[click here](https://example.com)") == "click here"
    end

    test "extracts image alt text" do
      assert Helpers.strip_markdown("![photo of a cat](cat.jpg)") == "photo of a cat"
    end

    test "removes fenced code blocks" do
      assert Helpers.strip_markdown("intro\n```elixir\nIO.puts(\"hi\")\n```\noutro") == "intro outro"
    end

    test "removes inline code" do
      assert Helpers.strip_markdown("use `IO.puts` to print") == "use to print"
    end

    test "strips HTML tags" do
      assert Helpers.strip_markdown("<p>Hello <strong>world</strong></p>") == "Hello world"
    end

    test "removes script tags case-insensitively" do
      assert Helpers.strip_markdown("before<SCRIPT>alert('x')</SCRIPT>after") == "beforeafter"
    end

    test "strips multiline headings" do
      input = "Line 1\n## Header\nLine 2"
      assert Helpers.strip_markdown(input) == "Line 1 Header Line 2"
    end

    test "truncates output to 160 characters" do
      long = String.duplicate("a", 200)
      assert Helpers.strip_markdown(long) |> String.length() == 160
    end

    test "returns empty string for empty input" do
      assert Helpers.strip_markdown("") == ""
    end
  end

  describe "format_date/1" do
    test "returns nil for nil" do
      assert Helpers.format_date(nil) == nil
    end

    test "formats a Date struct" do
      date = ~D[2026-01-15]
      assert Helpers.format_date(date) == "January 15, 2026"
    end

    test "formats a DateTime struct by converting to date first" do
      {:ok, datetime, _} = DateTime.from_iso8601("2026-01-15T12:30:00Z")
      assert Helpers.format_date(datetime) == "January 15, 2026"
    end

    test "formats an ISO 8601 string" do
      assert Helpers.format_date("2026-01-15T12:30:00Z") == "January 15, 2026"
    end

    test "returns the original string for an invalid ISO string" do
      assert Helpers.format_date("not-a-date") == "not-a-date"
    end

    test "returns the original string for an empty string" do
      assert Helpers.format_date("") == ""
    end
  end
end
