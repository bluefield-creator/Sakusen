defmodule SakusenWeb.UserSessionControllerTest do
  use SakusenWeb.ConnCase

  import Sakusen.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/log-in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "welcome back"

      response = conn |> get(~p"/") |> html_response(200)
      assert response =~ user.username
      assert response =~ ~p"/users/log-out"
    end

    test "sets the remember me cookie when asked", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "username" => user.username,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_sakusen_web_user_remember_me"]
    end

    test "welcomes a freshly registered user", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in?_action=registered", %{
          "user" => %{"username" => user.username, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "welcome"
    end

    test "redirects back with the username kept on invalid credentials", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"username" => user.username, "password" => "invalid_password"}
        })

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "wrong username or password"
      assert Phoenix.Flash.get(conn.assigns.flash, :username) == user.username
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "logged out"
    end
  end
end
