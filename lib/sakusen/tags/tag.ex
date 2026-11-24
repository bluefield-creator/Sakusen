defmodule Sakusen.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @categories [:general, :artist, :character, :copyright, :meta]

  schema "tags" do
    field :name, :string
    field :category, Ecto.Enum, values: @categories, default: :general
    field :post_count, :integer, default: 0

    many_to_many :posts, Sakusen.Posts.Post, join_through: Sakusen.Tags.PostTag

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :category])
    |> validate_required([:name, :category])
    |> validate_length(:name, max: 100)
    |> unique_constraint(:name)
  end
end
