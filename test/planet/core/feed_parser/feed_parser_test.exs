defmodule PlanetEx.Core.FeedParserTest do
  use ExUnit.Case
  alias PlanetEx.Core.FeedParser
  import PlanetExWeb.Support

  test "returns and empty string when it is passed an Feed" do
    assert FeedParser.parse("") == %FeedParser.Feed{}
  end

  describe "parse/1 for atom feeds" do
    @atom_feed atom_fixture([author: "Mitchell Hanberg"], 5)

    test "turns an atom feed into a Feed struct" do
      actual = FeedParser.parse(@atom_feed)

      assert %FeedParser.Feed{} = actual
    end

    test "parses the title, url, and author fields" do
      expected = %FeedParser.Feed{
        title: "Blog's Blog",
        url: "https://www.blog.com/",
        author: "Mitchell Hanberg"
      }

      actual = FeedParser.parse(@atom_feed)

      assert expected.title == actual.title
      assert expected.url == actual.url
      assert expected.author == actual.author
    end

    test "parses all entries" do
      actual = FeedParser.parse(@atom_feed)

      assert 5 == Enum.count(actual.entries)
      assert %FeedParser.Entry{} = List.first(actual.entries)
    end

    test "parses entry data from feed" do
      expected_entry = %FeedParser.Entry{
        title: "Blog title",
        url: "https://www.blog.com/path/to/blog/",
        author: "Mitchell Hanberg",
        content: "<blockquote>",
        published: Timex.parse!("2018-02-22T12:00:00+00:00", "{ISO:Extended}")
      }

      actual =
        @atom_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert expected_entry.title == actual.title
      assert expected_entry.url == actual.url
      assert expected_entry.author == actual.author
      assert actual.content =~ expected_entry.content
      assert expected_entry.published == actual.published
    end

    test "replaces empty entry author field with one from feed author field" do
      xml_feed = atom_fixture(author: "Mitchell Hanberg", entry: nil)

      expected_entry = %FeedParser.Entry{
        title: "Integrate and Deploy React with Phoenix",
        url:
          "https://www.mitchellhanberg.com/post/2018/02/22/integrate-and-deploy-react-with-phoenix",
        author: "Mitchell Hanberg",
        content: "<blockquote>",
        published: Timex.parse!("2018-02-22T12:00:00+00:00", "{ISO:Extended}")
      }

      actual =
        xml_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert expected_entry.author == actual.author
    end

    test "replaces relative links in href values with absolute ones" do
      expected_entry = %FeedParser.Entry{
        title: "Integrate and Deploy React with Phoenix",
        url:
          "https://www.mitchellhanberg.com/post/2018/02/22/integrate-and-deploy-react-with-phoenix",
        author: "Mitchell Hanberg",
        content: ~s{<a href="https://www.blog.com/relativelink">},
        published: Timex.parse!("2018-02-22T12:00:00+00:00", "{ISO:Extended}")
      }

      actual =
        @atom_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert actual.content =~ expected_entry.content
    end

    test "replaces relative img srcs with absolute ones" do
      expected_entry = %FeedParser.Entry{
        title: "Integrate and Deploy React with Phoenix",
        url:
          "https://www.mitchellhanberg.com/post/2018/02/22/integrate-and-deploy-react-with-phoenix",
        author: "Mitchell Hanberg",
        content: "<img src=\"https://www.blog.com/images/contact.png\"",
        published: Timex.parse!("2018-02-22T12:00:00+00:00", "{ISO:Extended}")
      }

      actual =
        @atom_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert actual.content =~ expected_entry.content
    end
  end

  describe "parse/1 for rss feeds" do
    @rss_feed rss_fixture(5)

    test "turns an rss feed into a Feed struct" do
      actual = FeedParser.parse(@rss_feed)

      assert %FeedParser.Feed{} = actual
    end

    test "parses the title and url fields" do
      expected = %FeedParser.Feed{
        title: "SEP Blog",
        url: "https://www.sep.com/sep-blog"
      }

      actual = FeedParser.parse(@rss_feed)

      assert expected.title == actual.title
      assert expected.url == actual.url
    end

    test "parses all entries" do
      actual = FeedParser.parse(@rss_feed)

      assert 5 == Enum.count(actual.entries)
      assert %FeedParser.Entry{} = List.first(actual.entries)
    end

    test "parses entry data from feed" do
      expected_entry = %FeedParser.Entry{
        title: "Blog title",
        url: "https://www.sep.com/sep-blog/path/to/blog/",
        content: "This is the content of this blog post",
        author: "SEPeer",
        published:
          Timex.parse!(
            "Tue, 19 Jun 2018 15:53:03 +0000",
            "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} {Z}"
          )
      }

      actual =
        @rss_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert expected_entry.title == actual.title
      assert expected_entry.url == actual.url
      assert actual.content =~ expected_entry.content
      assert expected_entry.published == actual.published
      assert expected_entry.author == actual.author
    end

    test "parses entry data from feed with only description field" do
      expected_entry = %FeedParser.Entry{
        title: "Blog title",
        url: "http://blog.com/path/to/post/",
        content: "<p>This is the body of this blog post</p>",
        author: nil,
        published:
          Timex.parse!(
            "Fri, 30 Dec 2016 16:25:00 +0000",
            "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} {Z}"
          )
      }

      actual =
        rss_fixture_only_description()
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert expected_entry.title == actual.title
      assert expected_entry.url == actual.url
      assert actual.content =~ expected_entry.content
      assert expected_entry.published == actual.published
      assert expected_entry.author == actual.author
    end
  end

  describe "parse/1 for sharepoint feeds" do
    @sharepoint_feed sharepoint_fixture()

    test "turns an html doc into a Feed struct" do
      actual = FeedParser.parse(@sharepoint_feed)

      assert %FeedParser.Feed{} = actual
    end

    test "parses the title and url fields" do
      expected = %FeedParser.Feed{
        title: "Blog: Posts",
        url: "https://sharepoint.sep.com:8383/personal/ohri/Blog/Lists/Posts/AllPosts.aspx"
      }

      actual = FeedParser.parse(@sharepoint_feed)

      assert expected.title == actual.title
    end

    test "parses all entries" do
      actual = FeedParser.parse(@sharepoint_feed)

      assert 1 == Enum.count(actual.entries)
      assert %FeedParser.Entry{} = List.first(actual.entries)
    end

    test "parses entry data from feed" do
      expected_entry = %FeedParser.Entry{
        title: "Blog title",
        url: "https://blog.com/post",
        content: "This is the body of the blog post.",
        author: "Blog Author",
        published:
          Timex.parse!(
            "Tue, 03 Jul 2018 15:07:18 GMT",
            "{WDshort}, {0D} {Mshort} {YYYY} {h24}:{m}:{s} {Zabbr}"
          )
      }

      actual =
        @sharepoint_feed
        |> FeedParser.parse()
        |> Map.get(:entries)
        |> List.first()

      assert expected_entry.title == actual.title
      assert expected_entry.url == actual.url
      assert actual.content =~ expected_entry.content
      assert expected_entry.published == actual.published
      assert expected_entry.author == actual.author
    end
  end
end
