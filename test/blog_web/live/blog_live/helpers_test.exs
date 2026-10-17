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

  describe "tag_names/1" do
    test "always prefixes the list with All" do
      assert Helpers.tag_names([%{"tags" => ["phoenix"]}]) == ["All", "phoenix"]
      assert Helpers.tag_names([]) == ["All"]
      assert Helpers.tag_names([%{}]) == ["All"]
    end

    test "collects unique sorted tags across posts" do
      posts = [
        %{"tags" => ["phoenix", "elixir"]},
        %{"tags" => ["liveview", "elixir"]}
      ]

      assert Helpers.tag_names(posts) == ["All", "elixir", "liveview", "phoenix"]
    end

    test "reads labels and categories keys and name maps" do
      posts = [
        %{"labels" => [%{"name" => "phoenix"}]},
        %{"categories" => ["elixir"]}
      ]

      assert Helpers.tag_names(posts) == ["All", "elixir", "phoenix"]
    end
  end
end
