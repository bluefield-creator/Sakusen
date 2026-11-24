defmodule Sakusen.PostsFixtures do
  @moduledoc "Test helpers for inserting posts without touching media files."

  alias Sakusen.Posts.Post
  alias Sakusen.Repo
  alias Sakusen.Tags

  def post_fixture(attrs \\ %{}) do
    {tag_input, attrs} = attrs |> Map.new() |> Map.pop(:tags, "")
    {uploader, attrs} = Map.pop(attrs, :uploader)

    post =
      %Post{
        sha256: random_hex(32),
        md5: random_hex(16),
        file_ext: "png",
        file_size: 12_345,
        width: 800,
        height: 600,
        rating: :general,
        uploader_id: uploader && uploader.id
      }
      |> struct!(attrs)
      |> Repo.insert!()

    {:ok, _tags} = Tags.put_post_tags(post, tag_input)
    Repo.preload(post, :tags, force: true)
  end

  defp random_hex(bytes), do: bytes |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
end
