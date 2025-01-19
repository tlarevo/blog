defmodule Blog do
  require Logger

  @moduledoc """
  Blog keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defp get_base_url() do
    Application.fetch_env!(:blog, :base_url)
  end

  defp get_headers() do
    Application.fetch_env!(:blog, :github_token)
    |> then(&[authorization: "Bearer #{&1}"])
  end

  defp build_list_posts_query(count, attr) do
    [
      repository:
        {[owner: "tlarevo", name: "blog"],
         [
           discussions:
             {[first: count, orderBy: [field: :CREATED_AT, direction: :DESC]], [nodes: attr]}
         ]}
    ]
  end

  defp build_fetch_post_query(id) do
    [
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
  end

  defp create_query_string(query) do
    Cognac.query(query, output: :binary)
  end

  def fetch_posts(count \\ 10, attr \\ [:id, :number, :title]) do
    build_list_posts_query(count, attr)
    |> create_query_string()
    |> then(fn query_string ->
      Req.new(url: get_base_url(), headers: get_headers())
      |> AbsintheClient.attach()
      |> Req.post(graphql: query_string)
    end)
    |> handle_response()
    |> process_data()
  end

  def fetch_post(id) do
    build_fetch_post_query(id)
    |> create_query_string()
    |> then(fn query_string ->
      Req.new(url: get_base_url(), headers: get_headers())
      |> AbsintheClient.attach()
      |> Req.post(graphql: query_string)
    end)
    |> handle_response()
    |> process_data()
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
