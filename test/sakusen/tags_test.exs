defmodule Sakusen.TagsTest do
  use Sakusen.DataCase

  import Sakusen.PostsFixtures

  alias Sakusen.Tags
  alias Sakusen.Tags.Tag

  test "put_post_tags/2 creates tags, honouring category prefixes" do
    post = post_fixture()

    assert {:ok, tags} =
             Tags.put_post_tags(post, "Artist:Some_Artist blue_hair :3 -excluded wild*")

    assert [{":3", :general}, {"blue_hair", :general}, {"some_artist", :artist}] =
             Enum.map(tags, &{&1.name, &1.category})

    assert [{:general, [_, _]}, {:artist, [%Tag{name: "some_artist"}]}] =
             Tags.tags_by_category(post)
  end

  test "put_post_tags/2 replaces the tag set and keeps post_count in step" do
    post = post_fixture(tags: "a b")
    post_fixture(tags: "b")

    assert {:ok, _} = Tags.put_post_tags(post, "b c")

    counts = Repo.all(from t in Tag, select: {t.name, t.post_count}, order_by: t.name)
    assert counts == [{"a", 0}, {"b", 2}, {"c", 1}]
  end
end
