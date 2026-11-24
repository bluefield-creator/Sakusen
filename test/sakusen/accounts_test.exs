defmodule Sakusen.AccountsTest do
  use Sakusen.DataCase

  alias Sakusen.Accounts
  alias Sakusen.Accounts.{User, UserToken}

  import Sakusen.AccountsFixtures

  describe "register_user/1" do
    test "registers a user with a hashed password" do
      {:ok, user} =
        Accounts.register_user(%{username: "Alice_1", password: valid_user_password()})

      assert user.username == "alice_1"
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end

    test "validates username and password" do
      {:error, changeset} =
        Accounts.register_user(%{
          username: "a!",
          password: "short",
          password_confirmation: "other"
        })

      errors = errors_on(changeset)
      assert "only letters, digits and underscores" in errors.username
      assert "should be at least 3 character(s)" in errors.username
      assert errors.password == ["should be at least 12 character(s)"]
      assert errors.password_confirmation == ["does not match password"]
    end

    test "validates username uniqueness case-insensitively" do
      %{username: username} = user_fixture()
      {:error, changeset} = Accounts.register_user(valid_user_attributes(username: username))
      assert "has already been taken" in errors_on(changeset).username

      {:error, changeset} =
        Accounts.register_user(valid_user_attributes(username: String.upcase(username)))

      assert "has already been taken" in errors_on(changeset).username
    end
  end

  describe "get_user_by_username_and_password/2" do
    test "returns the user only with the right password" do
      user = user_fixture()

      assert %User{id: id} =
               Accounts.get_user_by_username_and_password(user.username, valid_user_password())

      assert id == user.id
      refute Accounts.get_user_by_username_and_password(user.username, "invalid password")
      refute Accounts.get_user_by_username_and_password("nobody", valid_user_password())
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -11, :minute)}, -10)
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "updates the password and deletes all tokens", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {user, [_expired]}} =
        Accounts.update_user_password(user, %{password: "new valid password"})

      assert Accounts.get_user_by_username_and_password(user.username, "new valid password")
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "session tokens" do
    setup do
      user = user_fixture()
      %{user: user, token: Accounts.generate_user_session_token(user)}
    end

    test "returns the user for a valid token", %{user: user, token: token} do
      assert {session_user, _inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at
    end

    test "does not return the user for an invalid or expired token", %{token: token} do
      refute Accounts.get_user_by_session_token("oops")

      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end

    test "deletes the token", %{token: token} do
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  test "inspecting a user does not include the password" do
    refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
  end
end
