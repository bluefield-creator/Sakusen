defmodule SakusenWeb.UserSessionController do
  use SakusenWeb, :controller

  alias Sakusen.Accounts
  alias SakusenWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "welcome")
  end

  def create(conn, params) do
    create(conn, params, "welcome back")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"username" => username, "password" => password} = user_params

    if user = Accounts.get_user_by_username_and_password(username, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      conn
      |> put_flash(:error, "wrong username or password")
      |> put_flash(:username, String.slice(username, 0, 32))
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "password updated")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "logged out")
    |> UserAuth.log_out_user()
  end
end
