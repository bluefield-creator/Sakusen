defmodule Sakusen.PostsTest do
  use Sakusen.DataCase

  import Sakusen.AccountsFixtures

  alias Sakusen.Posts
  alias Sakusen.Posts.{Post, Storage}

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    on_exit(fn -> File.rm_rf!(Storage.root()) end)

    named_path = Path.join(tmp_dir, "red.png")
    Image.write!(Image.new!(4, 3, color: :red), named_path)

    extensionless_path = Path.join(tmp_dir, "upload")
    File.rename!(named_path, extensionless_path)

    %{scope: user_scope_fixture(), png_path: extensionless_path}
  end

  test "create_post/2 stores the file and thumbnail with real image facts", %{
    scope: scope,
    png_path: png_path
  } do
    assert {:ok, %Post{} = post} =
             Posts.create_post(scope, %{
               path: png_path,
               rating: "general",
               source: nil,
               tags: "red_square"
             })

    assert %{file_ext: "png", width: 4, height: 3, rating: :general} = post

    assert post.sha256 ==
             :crypto.hash(:sha256, File.read!(png_path)) |> Base.encode16(case: :lower)

    assert Enum.map(post.tags, & &1.name) == ["red_square"]
    assert File.exists?(Storage.original_path(post))
    assert File.exists?(Storage.thumbnail_path(post))
  end

  test "create_post/2 returns the existing post for a duplicate file", %{
    scope: scope,
    png_path: png_path
  } do
    attrs = %{path: png_path, rating: "general", source: nil, tags: ""}
    {:ok, post} = Posts.create_post(scope, attrs)

    assert {:error, {:duplicate, %Post{id: id}}} = Posts.create_post(scope, attrs)
    assert id == post.id
  end

  test "create_post/2 rejects files that are not supported images", %{
    scope: scope,
    tmp_dir: tmp_dir
  } do
    path = Path.join(tmp_dir, "notes.png")
    File.write!(path, "not an image")

    assert {:error, :unsupported_format} =
             Posts.create_post(scope, %{path: path, rating: "general", source: nil, tags: ""})
  end
end
