defmodule BlogTest do
  use ExUnit.Case, async: false

  test "fetch_posts returns a controlled error when GitHub token is missing" do
    previous_token = Application.get_env(:blog, :github_token)

    try do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_posts()
    after
      if is_nil(previous_token) do
        Application.delete_env(:blog, :github_token)
      else
        Application.put_env(:blog, :github_token, previous_token)
      end
    end
  end

  test "fetch_post returns a controlled error when GitHub token is missing" do
    previous_token = Application.get_env(:blog, :github_token)

    try do
      Application.delete_env(:blog, :github_token)

      assert {:error, :missing_github_token} = Blog.fetch_post(1)
    after
      if is_nil(previous_token) do
        Application.delete_env(:blog, :github_token)
      else
        Application.put_env(:blog, :github_token, previous_token)
      end
    end
  end
end
