defmodule Sakusen.Repo.Migrations.CreatePostsAndTags do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :uploader_id, references(:users, on_delete: :nilify_all)
      add :sha256, :string, null: false
      add :md5, :string, null: false
      add :file_ext, :string, null: false
      add :file_size, :integer, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false
      add :rating, :string, null: false
      add :source, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:posts, [:sha256])
    create index(:posts, [:md5])
    create index(:posts, [:uploader_id])
    create index(:posts, [:rating])

    create table(:tags) do
      add :name, :string, null: false
      add :category, :string, null: false, default: "general"
      add :post_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name])

    create table(:post_tags, primary_key: false) do
      add :post_id, references(:posts, on_delete: :delete_all), null: false, primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true
    end

    create index(:post_tags, [:tag_id])
  end
end
