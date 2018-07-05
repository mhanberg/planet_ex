defmodule Planet.Core.FeedParser do
  alias Planet.Core.FeedParser.{Feed, Entry}
  import SweetXml

  def parse(""), do: %Feed{}

  def parse(raw_feed) do
    parsed = SweetXml.parse(raw_feed)

    %Feed{}
    |> put_title(parsed)
    |> put_url(parsed)
    |> put_author(parsed)
    |> put_entries(raw_feed)
  end

  defp put_entries(%Feed{} = feed, xml) do
    entries =
      stream_tags(xml, :entry)
      |> Stream.map(fn entry -> to_entry(entry, feed) end)
      |> Enum.to_list()

    struct(feed, entries: entries)
  end

  defp to_entry({:entry, entryXml}, feed) do
    %Entry{}
    |> put_title(entryXml)
    |> put_url(entryXml)
    |> put_author(entryXml)
    |> put_content(entryXml, feed)
    |> put_published(entryXml)
  end

  defp put_content(%Entry{} = entry, xml, feed) do
    content =
      xpath(xml, ~x"./content/text()"s)
      |> String.replace(~r{(href|src)=(?:"|')/(.*)(?:"|')}, "\\1=\"#{feed.url}\\2\"")

    struct(entry, content: content)
  end

  defp put_published(%Entry{} = entry, xml) do
    published =
      xpath(xml, ~x"./published/text()"s)
      |> parse_date

    struct(entry, published: published)
  end

  defp parse_date(date) do
    Timex.parse!(date, "{ISO:Extended}")
  end

  defp put_title(struct, xml) do
    struct(struct, title: xpath(xml, ~x"./title/text()"s))
  end

  defp put_url(struct, xml) do
    struct(struct, url: xpath(xml, ~x"./id/text()"s))
  end

  defp put_author(struct, xml) do
    struct(struct, author: xpath(xml, ~x"./author/name/text()"s))
  end

  def merge(feeds) when is_list(feeds) do
    %Feed{
      title: "Planet: The Blogs of SEP",
      url: "https://planet.sep.com",
      author: "SEPeers",
      entries: combine_and_sort_entries(feeds)
    }
  end

  defp combine_and_sort_entries(feeds) do
    Enum.flat_map(feeds, & &1.entries)
    |> Enum.sort_by(& &1.published, &Timex.after?/2)
  end
end
