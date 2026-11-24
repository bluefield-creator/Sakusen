defmodule Sakusen.SearchTest do
  use Sakusen.DataCase

  import Sakusen.AccountsFixtures
  import Sakusen.PostsFixtures

  alias Sakusen.Search

  defp ids(query) do
    {:ok, %{posts: posts}} = Search.search_posts(query)
    posts |> Enum.map(& &1.id) |> Enum.sort()
  end

  test "combines tags with AND and excludes negated tags" do
    both = post_fixture(tags: "cat hat")
    cat = post_fixture(tags: "cat")

    assert ids("cat hat") == [both.id]
    assert ids("cat -hat") == [cat.id]
  end

  test "wildcards match by LIKE with underscores taken literally" do
    blue = post_fixture(tags: "blue_hair")
    post_fixture(tags: "bluexhair")

    assert ids("blue_*") == [blue.id]
    assert ids("*_hair") == [blue.id]
  end

  test "~ terms form one OR group" do
    cat = post_fixture(tags: "cat")
    dog = post_fixture(tags: "dog")
    post_fixture(tags: "bird")

    assert ids("~cat ~dog") == Enum.sort([cat.id, dog.id])
  end

  test "filters by rating, width and uploader" do
    uploader = user_fixture(%{username: "alice"})
    wide = post_fixture(rating: :explicit, width: 2000, uploader: uploader)
    post_fixture(rating: :explicit, width: 500)
    post_fixture(rating: :general, width: 2000)

    assert ids("rating:e width:>=1000") == [wide.id]
    assert ids("user:Alice") == [wide.id]
  end

  test "rejects invalid metatag values" do
    assert {:error, _} = Search.search_posts("rating:x")
    assert {:error, _} = Search.search_posts("width:>abc")
  end
end
