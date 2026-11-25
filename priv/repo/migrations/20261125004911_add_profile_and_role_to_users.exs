defmodule Sakusen.Repo.Migrations.AddProfileAndRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false, default: "user"
      add :display_name, :string
      add :bio, :text
      add :avatar_key, :string
      add :banner_key, :string
    end
  end
end
