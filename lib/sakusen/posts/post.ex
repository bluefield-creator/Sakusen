defmodule Sakusen.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @ratings [:general, :sensitive, :questionable, :explicit]
  @file_exts ~w(jpg png gif webp)

  schema "posts" do
    field :sha256, :string
    field :md5, :string
    field :file_ext, :string
    field :file_size, :integer
    field :width, :integer
    field :height, :integer
    field :rating, Ecto.Enum, values: @ratings
    field :source, :string

    belongs_to :uploader, Sakusen.Accounts.User
    many_to_many :tags, Sakusen.Tags.Tag, join_through: Sakusen.Tags.PostTag

    timestamps(type: :utc_datetime)
  end

  def ratings, do: @ratings
  def file_exts, do: @file_exts

  def metadata_changeset(post, attrs) do
    post
    |> cast(attrs, [:rating, :source])
    |> validate_required([:rating])
    |> validate_length(:source, max: 2048)
  end

  def upload_changeset(post, attrs) do
    post
    |> cast(attrs, [:sha256, :md5, :file_ext, :file_size, :width, :height, :uploader_id])
    |> validate_required([:sha256, :md5, :file_ext, :file_size, :width, :height])
    |> validate_inclusion(:file_ext, @file_exts)
    |> unique_constraint(:sha256)
  end
end
