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

  @words_per_minute 200

  def reading_time(nil), do: nil

  def reading_time(body) when is_binary(body) do
    words =
      body
      |> String.split(~r/\s+/, trim: true)
      |> length()

    max(div(words + @words_per_minute - 1, @words_per_minute), 1)
  end

  defp format_date_parts(year, month, day) do
    month_name = Enum.at(@months, month - 1) || "Unknown"
    "#{month_name} #{day}, #{year}"
  end
end
