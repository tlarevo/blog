defmodule Blog do
  require Logger

  @moduledoc """
  Blog keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def fetch_posts(count \\ 10, attr \\ [:id, :number, :title]) do
    base_url = "https://api.github.com/graphql"

    headers =
      [authorization: "Bearer #{Application.fetch_env!(:blog, :github_token)}"]

    query = [
      repository:
        {[owner: "tlarevo", name: "blog"],
         [
           discussions:
             {[first: count, orderBy: [field: :CREATED_AT, direction: :DESC]], [nodes: attr]}
         ]}
    ]

    query_string = Cognac.query(query, output: :binary)
    request = Req.new(url: base_url, headers: headers) |> AbsintheClient.attach()

    Req.post(request, graphql: query_string) |> handle_response() |> process_data()
  end

  def fetch_post(id) do
    base_url = "https://api.github.com/graphql"

    headers = [authorization: "Bearer #{Application.fetch_env!(:blog, :github_token)}"]

    query = [
      repository:
        {[owner: "tlarevo", name: "blog"],
         [
           discussion:
             {[number: id],
              [
                :id,
                :number,
                :title,
                :body,
                comments:
                  {[first: 10], [:totalCount, nodes: [:id, :body, :createdAt, :updatedAt]]}
              ]}
         ]}
    ]

    query_string = Cognac.query(query, output: :binary)
    request = Req.new(url: base_url, headers: headers) |> AbsintheClient.attach()
    Req.post(request, graphql: query_string) |> handle_response() |> process_data()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}), do: body
  defp handle_response({:error, reason}), do: log_error_and_return_nil(reason)
  defp handle_response(_), do: nil

  defp log_error_and_return_nil(reason) do
    Logger.error("Failed to fetch discussion titles: #{inspect(reason)}")
    nil
  end

  defp process_data(%{"data" => %{"repository" => %{"discussions" => %{"nodes" => nodes}}}}),
    do: nodes

  defp process_data(%{"data" => %{"repository" => %{"discussion" => discussion}}}),
    do: discussion

  defp process_data(nil), do: nil
end
