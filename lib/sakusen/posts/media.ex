defmodule Sakusen.Posts.Media do
  @moduledoc "Content-addressed storage keys for post originals and thumbnails, sharded by SHA-256 prefix."

  alias Sakusen.Posts.Post
  alias Sakusen.Storage

  @thumbnail_ext "webp"

  def original_key(%Post{sha256: sha256, file_ext: ext}), do: shard_key("original", sha256, ext)

  def thumbnail_key(%Post{sha256: sha256}), do: shard_key("thumbnail", sha256, @thumbnail_ext)

  def original_url(%Post{} = post), do: post |> original_key() |> Storage.url()

  def thumbnail_url(%Post{} = post), do: post |> thumbnail_key() |> Storage.url()

  def shard_key(prefix, <<a::binary-size(2), b::binary-size(2), _::binary>> = sha256, ext),
    do: Enum.join([prefix, a, b, "#{sha256}.#{ext}"], "/")
end
