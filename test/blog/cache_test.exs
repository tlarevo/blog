defmodule Blog.CacheTest do
  use ExUnit.Case, async: false

  setup do
    # Ensure the cache GenServer is started (idempotent)
    unless Process.whereis(Blog.Cache) do
      {:ok, _} = Blog.Cache.start_link()
    else
      # Recreate table if a previous test deleted it
      unless :ets.info(:blog_cache) != :undefined do
        Blog.Cache.init([])
      end
    end

    :ok
  end

  describe "get/1 and put/2" do
    test "returns nil for a cache miss" do
      assert Blog.Cache.get(:nonexistent) == nil
    end

    test "stores and retrieves a value" do
      Blog.Cache.put(:key1, {:ok, "data"})
      assert Blog.Cache.get(:key1) == {:ok, "data"}
    end

    test "overwrites an existing key" do
      Blog.Cache.put(:key2, "first")
      Blog.Cache.put(:key2, "second")
      assert Blog.Cache.get(:key2) == "second"
    end
  end

  describe "TTL expiry" do
    test "returns nil after TTL expires" do
      # Insert directly into ETS with an already-expired timestamp
      expired_at = System.monotonic_time(:millisecond) - 1
      :ets.insert(:blog_cache, {:ttl_test, "stale", expired_at})

      assert Blog.Cache.get(:ttl_test) == nil
    end
  end

  describe "table absent (graceful degradation)" do
    test "get returns nil when table does not exist" do
      :ets.delete(:blog_cache)

      assert Blog.Cache.get(:anything) == nil

      # Recreate for other tests
      Blog.Cache.init([])
    end

    test "put returns :ok when table does not exist" do
      :ets.delete(:blog_cache)

      assert Blog.Cache.put(:anything, "value") == :ok

      # Recreate for other tests
      Blog.Cache.init([])
    end
  end
end
