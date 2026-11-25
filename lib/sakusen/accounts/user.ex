defmodule Sakusen.Accounts.User do
  @moduledoc "A registered account, identified by its username."

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :authenticated_at, :utc_datetime, virtual: true
    field :role, Ecto.Enum, values: [:user, :admin], default: :user
    field :display_name, :string
    field :bio, :string
    field :avatar_key, :string
    field :banner_key, :string

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_username(opts)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name, :bio])
    |> update_change(:display_name, &String.trim/1)
    |> validate_length(:display_name, max: 64)
    |> validate_length(:bio, max: 1000)
  end

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp validate_username(changeset, opts) do
    changeset
    |> update_change(:username, &String.downcase/1)
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 32)
    |> validate_format(:username, ~r/^[a-z0-9_]+$/,
      message: "only letters, digits and underscores"
    )
    |> validate_username_unique(opts)
  end

  defp validate_username_unique(changeset, opts) do
    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:username, Sakusen.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
