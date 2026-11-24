defmodule Sakusen.Posts.Storage do
  @moduledoc """
  Content-addressed media layout: originals and thumbnails sharded by SHA-256 prefix.
  """

  alias Sakusen.Posts.Post

  @url_prefix "/media"
  @thumbnail_ext "webp"

  def root, do: Application.fetch_env!(:sakusen, :media_root)

  def url_prefix, do: @url_prefix

  def original_path(%Post{sha256: sha256, file_ext: ext}), do: original_path(sha256, ext)
  def original_path(sha256, ext), do: Path.join([root() | original_segments(sha256, ext)])

  def thumbnail_path(%Post{sha256: sha256}), do: thumbnail_path(sha256)
  def thumbnail_path(sha256), do: Path.join([root() | thumbnail_segments(sha256)])

  def original_url(%Post{sha256: sha256, file_ext: ext}),
    do: Enum.join([@url_prefix | original_segments(sha256, ext)], "/")

  def thumbnail_url(%Post{sha256: sha256}),
    do: Enum.join([@url_prefix | thumbnail_segments(sha256)], "/")

  defp original_segments(sha256, ext), do: ["original" | shard(sha256, "#{sha256}.#{ext}")]

  defp thumbnail_segments(sha256),
    do: ["thumbnail" | shard(sha256, "#{sha256}.#{@thumbnail_ext}")]

  defp shard(<<a::binary-size(2), b::binary-size(2), _::binary>>, file), do: [a, b, file]
end
