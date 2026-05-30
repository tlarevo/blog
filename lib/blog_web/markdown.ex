defmodule BlogWeb.Markdown do
  @moduledoc false

  def to_html(markdown) when is_binary(markdown) do
    markdown
    |> MDEx.to_html!(
      extension: [
        autolink: true,
        strikethrough: true,
        table: true,
        tasklist: true
      ],
      render: [unsafe: true],
      sanitize: MDEx.Document.default_sanitize_options()
    )
    |> Phoenix.HTML.raw()
  end

  def to_html(_markdown), do: Phoenix.HTML.raw("")
end
