defmodule Sakusen.Repo.Migrations.RemoveEmailFromUsers do
  use Ecto.Migration

  def up do
    drop index(:users, [:email])

    alter table(:users) do
      remove :email
      remove :confirmed_at
    end
  end

  def down do
    alter table(:users) do
      add :email, :string, collate: :nocase
      add :confirmed_at, :utc_datetime
    end

    create unique_index(:users, [:email])
  end
end
