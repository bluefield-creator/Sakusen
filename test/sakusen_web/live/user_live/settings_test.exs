defmodule SakusenWeb.UserLive.SettingsTest do
  use SakusenWeb.ConnCase

  alias Sakusen.Accounts
  import Phoenix.LiveViewTest
  import Sakusen.AccountsFixtures

  test "redirects if user is not logged in", %{conn: conn} do
    assert {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/users/settings")
    assert path == ~p"/users/log-in"
    assert %{"error" => "log in first"} = flash
  end

  test "redirects if user is not in sudo mode", %{conn: conn} do
    {:ok, conn} =
      conn
      |> log_in_user(user_fixture(),
        token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
      )
      |> live(~p"/users/settings")
      |> follow_redirect(conn, ~p"/users/log-in")

    assert conn.resp_body =~ "log in again"
  end

  describe "update password form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the password and re-issues the session", %{conn: conn, user: user} do
      new_password = "a brand new password"
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form =
        form(lv, "#password_form", %{
          "user" => %{
            "username" => user.username,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)
      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "password updated"

      assert Accounts.get_user_by_username_and_password(user.username, new_password)
    end

    test "renders errors with invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{"password" => "too short", "password_confirmation" => "does not match"}
        })
        |> render_submit()

      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end
  end
end
