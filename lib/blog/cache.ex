defmodule Blog.Cache do
  @moduledoc false
  use GenServer

  @table :blog_cache
  @ttl_ms :timer.minutes(5)

  # --- Client API (direct ETS, no GenServer call overhead) ---

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key) do
    with table when is_reference(table) <- :ets.whereis(@table) do
      case :ets.lookup(table, key) do
        [{^key, value, expires_at}] ->
          if System.monotonic_time(:millisecond) < expires_at do
            value
          else
            :ets.delete(table, key)
            nil
          end

        [] ->
          nil
      end
    else
      _ -> nil
    end
  end

  def put(key, value) do
    with table when is_reference(table) <- :ets.whereis(@table) do
      expires_at = System.monotonic_time(:millisecond) + @ttl_ms
      :ets.insert(table, {key, value, expires_at})
    else
      _ -> :ok
    end
  end

  # --- Server (owns the ETS table) ---

  @impl true
  def init([]) do
    table =
      try do
        :ets.new(@table, [:named_table, :public, read_concurrency: true])
      rescue
        ArgumentError -> :ets.info(@table)
      end

    {:ok, %{table: table}}
  end
end
