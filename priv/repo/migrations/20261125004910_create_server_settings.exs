defmodule Sakusen.Repo.Migrations.CreateServerSettings do
  use Ecto.Migration

  def change do
    create table(:server_settings) do
      add :storage_backend, :string, null: false, default: "local"
      add :s3_endpoint, :string
      add :s3_region, :string
      add :s3_bucket, :string
      add :s3_access_key_id, :string
      add :s3_secret_access_key, :binary
      add :s3_public_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
