defmodule BlogWeb.BlogLive.Helpers do
  @moduledoc false

  @months ~w(January February March April May June July August September October November December)

  def format_date(nil), do: nil

  def format_date(%Date{} = date), do: format_date_parts(date.year, date.month, date.day)

  def format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> format_date()
  end

  def format_date(iso_datetime) when is_binary(iso_datetime) do
    with {:ok, datetime, _offset} <- DateTime.from_iso8601(iso_datetime) do
      format_date(datetime)
    else
      _invalid -> iso_datetime
    end
  end

  @tag_keys ~w(tags labels categories)

  @all_tag "All"

  @doc """
  Returns the sorted unique tag names carried by `posts`, prefixed by "All".
  """
  def tag_names(posts) when is_list(posts) do
    posts
    |> Enum.flat_map(&post_tags/1)
    |> Enum.map(&tag_label/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> then(&[@all_tag | &1])
  end

  @doc """
  Filters `posts` down to those carrying the selected `tag`.

  Uses the same tag extraction as `tag_names/1`, so selecting a chip shows
  exactly the posts that contributed that chip. The `"All"` sentinel (or a
  blank/`nil` selection) disables the filter and returns every post.
  """
  def filter_by_tag(posts, tag) when is_list(posts) do
    case tag_label(tag) do
      selected when selected in [nil, @all_tag] -> posts
      selected -> Enum.filter(posts, &post_has_tag?(&1, selected))
    end
  end

  @words_per_minute 200

  def reading_time(nil), do: nil

  def reading_time(body) when is_binary(body) do
    words =
      body
      |> String.split(~r/\s+/, trim: true)
      |> length()

    max(div(words + @words_per_minute - 1, @words_per_minute), 1)
  end

  defp post_has_tag?(post, tag) do
    post
    |> post_tags()
    |> Enum.map(&tag_label/1)
    |> Enum.member?(tag)
  end

  defp post_tags(post) when is_map(post) do
    Enum.find_value(@tag_keys, [], fn key -> Map.get(post, key) end)
  end

  defp post_tags(_post), do: []

  defp tag_label(tag) when is_binary(tag) do
    case String.trim(tag) do
      "" -> nil
      label -> label
    end
  end

  defp tag_label(%{"name" => name}) when is_binary(name), do: tag_label(name)
  defp tag_label(_tag), do: nil

  defp format_date_parts(year, month, day) do
    month_name = Enum.at(@months, month - 1) || "Unknown"
    "#{month_name} #{day}, #{year}"
  end
end
