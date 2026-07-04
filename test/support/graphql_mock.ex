defmodule Blog.GraphQLMock do
  @moduledoc false

  @doc """
  Starts a mock HTTP server on a random port.
  Returns `{name, port}` where name is used to stop it later.
  """
  def start do
    name = make_ref()

    {:ok, socket} =
      :gen_tcp.listen(0, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true
      ])

    {:ok, port} = :inet.port(socket)

    # Spawn an acceptor loop
    pid = spawn_link(fn -> accept_loop(socket) end)
    Process.put({:mock_server, name}, {pid, socket})
    {name, port}
  end

  @doc "Stops the mock server."
  def stop(name) do
    case Process.get({:mock_server, name}) do
      {pid, socket} ->
        Process.exit(pid, :normal)
        :gen_tcp.close(socket)
        Process.delete({:mock_server, name})

      _ ->
        :ok
    end
  end

  # ── Handler functions (set via Application env) ─────────────

  @doc "Returns a handler that always returns the given status + body map."
  def static_response(status, body) do
    fn _req_body ->
      {status, Jason.encode!(body)}
    end
  end

  @doc """
  Returns a handler that fails `fail_count` times, then succeeds.
  Uses an Agent to track the attempt count.
  """
  def retry_handler(fail_count, fail_status, fail_body, success_body) do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    Process.put(:retry_agent, agent)

    fn _req_body ->
      attempt = Agent.get_and_update(agent, &{&1, &1 + 1})

      if attempt < fail_count do
        {fail_status, Jason.encode!(fail_body)}
      else
        {200, Jason.encode!(success_body)}
      end
    end
  end

  # ── Internal ────────────────────────────────────────────────

  defp accept_loop(listen_socket) do
    case :gen_tcp.accept(listen_socket, 2000) do
      {:ok, client} ->
        spawn(fn -> handle_client(client) end)
        accept_loop(listen_socket)

      {:error, :timeout} ->
        accept_loop(listen_socket)

      {:error, :closed} ->
        :ok
    end
  end

  defp handle_client(client) do
    case :gen_tcp.recv(client, 0, 5000) do
      {:ok, data} ->
        {status, body} = dispatch_request(data)
        response = "HTTP/1.1 #{status} OK\r\ncontent-type: application/json\r\ncontent-length: #{byte_size(body)}\r\n\r\n#{body}"
        :gen_tcp.send(client, response)
        :gen_tcp.close(client)

      {:error, _} ->
        :gen_tcp.close(client)
    end
  end

  defp dispatch_request(raw_request) do
    # Extract body from HTTP request
    case extract_body(raw_request) do
      nil ->
        {400, Jason.encode!(%{error: "no body"})}

      body ->
        case Application.get_env(:blog, :mock_handler) do
          handler when is_function(handler, 1) ->
            handler.(body)

          _ ->
            {200, Jason.encode!(default_posts_response())}
        end
    end
  end

  defp extract_body(raw) do
    case String.split(raw, "\r\n\r\n", parts: 2) do
      [_headers, body] -> body
      _ -> nil
    end
  end

  defp default_posts_response do
    %{
      "data" => %{
        "repository" => %{
          "discussions" => %{
            "nodes" => [
              %{
                "id" => "D_1",
                "number" => 1,
                "title" => "First Post",
                "createdAt" => "2026-01-01T00:00:00Z"
              },
              %{
                "id" => "D_2",
                "number" => 2,
                "title" => "Second Post",
                "createdAt" => "2025-12-31T00:00:00Z"
              }
            ],
            "pageInfo" => %{
              "hasNextPage" => true,
              "endCursor" => "cursor_abc"
            }
          }
        }
      }
    }
  end
end
