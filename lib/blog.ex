defmodule Blog do
  @moduledoc """
  Fetches blog posts from GitHub Discussions via GraphQL.

  Results are cached in ETS with a 5-minute TTL. Failed requests
  are retried up to 3 times with exponential backoff.
  """

  require Logger

  @github_graphql_url "https://api.github.com/graphql"
  @max_retries 3
  @base_retry_delay_ms 200

  # ── Public API ────────────────────────────────────────────────

  @spec fetch_posts(pos_integer(), [atom()], String.t() | nil) ::
          {:ok, %{posts: [map()], has_next_page: boolean(), end_cursor: String.t() | nil}}
          | {:error, term()}
  def fetch_posts(count \\ 10, attr \\ [:id, :number, :title, :createdAt], after_cursor \\ nil) do
    cache_key = {:posts, count, attr, after_cursor}

    case Blog.Cache.get(cache_key) do
      nil ->
        result = do_fetch_posts(count, attr, after_cursor)

        case result do
          {:ok, _data} -> Blog.Cache.put(cache_key, result)
          _ -> :ok
        end

        result

      cached ->
        cached
    end
  end

  @spec fetch_post(integer() | String.t()) :: {:ok, map()} | {:error, term()}
  def fetch_post(number) do
    cache_key = {:post, number}

    case Blog.Cache.get(cache_key) do
      nil ->
        result = do_fetch_post(number)

        case result do
          {:ok, _data} -> Blog.Cache.put(cache_key, result)
          _ -> :ok
        end

        result

      cached ->
        cached
    end
  end

  # ── Internal ──────────────────────────────────────────────────

  defp do_fetch_posts(count, attr, after_cursor) do
    with {:ok, token} <- github_token() do
      cursor_args = if after_cursor, do: [after: after_cursor], else: []

      query = [
        repository:
          {[owner: "tlarevo", name: "blog"],
           [
             discussions:
               {[
                  first: count,
                  orderBy: [field: :CREATED_AT, direction: :DESC]
                ] ++ cursor_args, [nodes: attr, pageInfo: [:hasNextPage, :endCursor]]}
           ]}
      ]

      query
      |> run_query_with_retry(token)
      |> process_data(:posts)
    end
  end

  defp do_fetch_post(number) do
    with {:ok, token} <- github_token(),
         {:ok, discussion_number} <- to_discussion_number(number) do
      query = [
        repository:
          {[owner: "tlarevo", name: "blog"],
           [
             discussion:
               {[number: discussion_number],
                [
                  :id,
                  :number,
                  :title,
                  :body,
                  :createdAt,
                  comments:
                    {[first: 10], [:totalCount, nodes: [:id, :body, :createdAt, :updatedAt]]}
                ]}
           ]}
      ]

      query
      |> run_query_with_retry(token)
      |> process_data(:post)
    end
  end

  defp github_token do
    case Application.get_env(:blog, :github_token) do
      token when is_binary(token) and token != "" -> {:ok, token}
      _missing_or_blank -> {:error, :missing_github_token}
    end
  end

  defp to_discussion_number(number) when is_integer(number), do: {:ok, number}

  defp to_discussion_number(number) when is_binary(number) do
    case Integer.parse(number) do
      {parsed, ""} -> {:ok, parsed}
      _invalid -> {:error, :invalid_discussion_number}
    end
  end

  defp run_query_with_retry(query, token, attempt \\ 1) do
    case run_query(query, token) do
      {:error, reason} when attempt < @max_retries and reason != :missing_github_token ->
        delay = @base_retry_delay_ms * Integer.pow(2, attempt - 1)
        Logger.warning("GitHub request failed (attempt #{attempt}/#{ @max_retries}), retrying in #{delay}ms: #{inspect(reason)}")
        Process.sleep(delay)
        run_query_with_retry(query, token, attempt + 1)

      result ->
        result
    end
  end

  defp run_query(query, token) do
    query_string = Cognac.query(query, output: :binary)
    request = Req.new(url: @github_graphql_url, headers: [authorization: "Bearer #{token}"])

    request
    |> AbsintheClient.attach()
    |> Req.post(graphql: query_string)
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: %{"errors" => errors}}}) do
    Logger.error("GitHub GraphQL errors: #{inspect(errors)}")
    {:error, :github_graphql_error}
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}), do: {:ok, body}

  defp handle_response({:ok, %Req.Response{status: status}}) do
    Logger.error("GitHub GraphQL request failed with status #{status}")
    {:error, :github_request_failed}
  end

  defp handle_response({:error, reason}) do
    Logger.error("GitHub GraphQL request failed: #{inspect(reason)}")
    {:error, :github_request_failed}
  end

  defp process_data(
         {:ok,
          %{
            "data" => %{
              "repository" => %{
                "discussions" => %{"nodes" => nodes, "pageInfo" => page_info}
              }
            }
          }},
         :posts
       ) do
    with nodes when is_list(nodes) <- nodes do
      {:ok,
       %{
         posts: nodes,
         has_next_page: page_info["hasNextPage"],
         end_cursor: page_info["endCursor"]
       }}
    else
      _unexpected -> {:error, :unexpected_github_response}
    end
  end

  defp process_data({:ok, %{"data" => %{"repository" => %{"discussion" => nil}}}}, :post),
    do: {:error, :not_found}

  defp process_data({:ok, %{"data" => %{"repository" => %{"discussion" => discussion}}}}, :post),
    do: {:ok, discussion}

  defp process_data({:error, reason}, _type), do: {:error, reason}
  defp process_data(_unexpected, _type), do: {:error, :unexpected_github_response}
end
