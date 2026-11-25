defmodule Sakusen.Accounts do
  @moduledoc "User accounts: registration, credentials, sessions and profiles."

  import Ecto.Query, warn: false
  alias Sakusen.Repo

  alias Sakusen.Accounts.{User, UserToken}
  alias Sakusen.Accounts.{ProfileImage, Scope}
  alias Sakusen.Storage

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: String.downcase(username))
  end

  def get_user_by_username!(username) when is_binary(username) do
    Repo.get_by!(User, username: String.downcase(username))
  end

  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = get_user_by_username(username)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(attrs) do
    Repo.transact(fn ->
      %User{}
      |> User.registration_changeset(attrs)
      |> grant_admin_to_first_user()
      |> Repo.insert()
    end)
  end

  defp grant_admin_to_first_user(changeset) do
    if Repo.exists?(User) do
      changeset
    else
      Ecto.Changeset.put_change(changeset, :role, :admin)
    end
  end

  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  def update_user_profile(%Scope{user: user}, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def update_user_avatar(%Scope{user: user}, path), do: replace_profile_image(user, :avatar, path)

  def update_user_banner(%Scope{user: user}, path), do: replace_profile_image(user, :banner, path)

  def avatar_url(%User{avatar_key: key}), do: key && Storage.url(key)

  def banner_url(%User{banner_key: key}), do: key && Storage.url(key)

  defp replace_profile_image(user, kind, path) do
    field = profile_image_field(kind)
    previous_key = Map.fetch!(user, field)

    with {:ok, %{key: key, data: data}} <- ProfileImage.process(kind, path),
         :ok <- Storage.put(key, {:data, data}, "image/webp") do
      case user |> Ecto.Changeset.change(%{field => key}) |> Repo.update() do
        {:ok, updated} ->
          if previous_key && previous_key != key, do: Storage.delete(previous_key)
          {:ok, updated}

        {:error, _changeset} = error ->
          if previous_key != key, do: Storage.delete(key)
          error
      end
    end
  end

  defp profile_image_field(:avatar), do: :avatar_key
  defp profile_image_field(:banner), do: :banner_key

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
