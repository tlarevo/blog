defmodule Blog do
  require Logger

  @moduledoc """
  Blog keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @github_graphql_url "https://api.github.com/graphql"

  def fetch_posts(count \\ 10, attr \\ [:id, :number, :title, :createdAt]) do
    with {:ok, token} <- github_token() do
      query = [
        repository:
          {[owner: "tlarevo", name: "blog"],
           [
             discussions:
               {[first: count, orderBy: [field: :CREATED_AT, direction: :DESC]], [nodes: attr]}
           ]}
      ]

      query
      |> run_query(token)
      |> process_data(:posts)
    end
  end

  def fetch_post(number) do
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
      |> run_query(token)
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
         {:ok, %{"data" => %{"repository" => %{"discussions" => %{"nodes" => nodes}}}}},
         :posts
       ),
       do: {:ok, nodes}

  defp process_data({:ok, %{"data" => %{"repository" => %{"discussion" => nil}}}}, :post),
    do: {:error, :not_found}

  defp process_data({:ok, %{"data" => %{"repository" => %{"discussion" => discussion}}}}, :post),
    do: {:ok, discussion}

  defp process_data({:error, reason}, _type), do: {:error, reason}
  defp process_data(_unexpected, _type), do: {:error, :unexpected_github_response}
end
