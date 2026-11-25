defmodule Sakusen.Posts do
  @moduledoc "Uploading, storing and retrieving posts and their media files."

  import Ecto.Query, only: [from: 2]

  alias Sakusen.Accounts.{Scope, User}
  alias Sakusen.Posts.{Media, Post}
  alias Sakusen.Repo
  alias Sakusen.Storage
  alias Sakusen.Tags

  @file_exts_by_loader %{
    "jpegload" => "jpg",
    "pngload" => "png",
    "gifload" => "gif",
    "webpload" => "webp"
  }

  @thumbnail_box "300x300"
  @hash_chunk_bytes 2_097_152

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:uploader, :tags])
  end

  def count_posts_by_uploader(%User{id: uploader_id}) do
    Repo.aggregate(from(p in Post, where: p.uploader_id == ^uploader_id), :count)
  end

  def change_post_metadata(post \\ %Post{}, attrs \\ %{}) do
    Post.metadata_changeset(post, attrs)
  end

  def create_post(%Scope{user: uploader}, %{path: path} = attrs) do
    digests = digest_file(path)

    with :ok <- ensure_not_duplicate(digests.sha256),
         {:ok, media} <- inspect_media(path) do
      file_facts =
        digests
        |> Map.merge(Map.take(media, [:file_ext, :width, :height]))
        |> Map.merge(%{file_size: File.stat!(path).size, uploader_id: uploader.id})

      changeset =
        %Post{}
        |> Post.metadata_changeset(Map.take(attrs, [:rating, :source]))
        |> Post.upload_changeset(file_facts)

      Repo.transact(fn ->
        with {:ok, post} <- Repo.insert(changeset),
             {:ok, _tags} <- Tags.put_post_tags(post, Map.get(attrs, :tags) || ""),
             :ok <- store_media(post, path, media.image) do
          {:ok, Repo.preload(post, [:uploader, :tags], force: true)}
        end
      end)
    end
  end

  defp digest_file(path) do
    {sha256, md5} =
      path
      |> File.stream!(@hash_chunk_bytes)
      |> Enum.reduce({:crypto.hash_init(:sha256), :crypto.hash_init(:md5)}, fn chunk,
                                                                               {sha256, md5} ->
        {:crypto.hash_update(sha256, chunk), :crypto.hash_update(md5, chunk)}
      end)

    %{sha256: hex(:crypto.hash_final(sha256)), md5: hex(:crypto.hash_final(md5))}
  end

  defp hex(digest), do: Base.encode16(digest, case: :lower)

  defp ensure_not_duplicate(sha256) do
    case Repo.get_by(Post, sha256: sha256) do
      nil -> :ok
      existing -> {:error, {:duplicate, existing}}
    end
  end

  defp inspect_media(path) do
    with {:ok, image} <- Image.open(path),
         {:ok, file_ext} <- detect_file_ext(image) do
      {:ok,
       %{image: image, file_ext: file_ext, width: Image.width(image), height: frame_height(image)}}
    else
      _ -> {:error, :unsupported_format}
    end
  end

  defp detect_file_ext(image) do
    with {:ok, loader} <- Vix.Vips.Image.header_value(image, "vips-loader") do
      [loader_family | _] = String.split(loader, "_")
      Map.fetch(@file_exts_by_loader, loader_family)
    end
  end

  defp frame_height(image) do
    case Vix.Vips.Image.header_value(image, "page-height") do
      {:ok, page_height} when page_height > 0 -> page_height
      _ -> Image.height(image)
    end
  end

  defp store_media(post, source_path, image) do
    original_key = Media.original_key(post)
    thumbnail_key = Media.thumbnail_key(post)

    with :ok <- Storage.put(original_key, {:path, source_path}, MIME.type(post.file_ext)),
         {:ok, thumbnail} <- Image.thumbnail(image, @thumbnail_box, resize: :down),
         {:ok, webp} <- Image.write(thumbnail, :memory, suffix: ".webp"),
         :ok <- Storage.put(thumbnail_key, {:data, webp}, "image/webp") do
      :ok
    else
      error ->
        Storage.delete(original_key)
        Storage.delete(thumbnail_key)
        error
    end
  end
end
