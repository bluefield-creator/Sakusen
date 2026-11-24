defmodule SakusenWeb.UserLive.LoginTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.AccountsFixtures

  test "renders login page", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/users/log-in")

    assert html =~ "Log in"
    assert html =~ "Sign up"
    assert html =~ "Remember me"
  end

  test "logs in with valid credentials", %{conn: conn} do
    user = user_fixture()
    {:ok, lv, _html} = live(conn, ~p"/users/log-in")

    form =
      form(lv, "#login_form",
        user: %{username: user.username, password: valid_user_password(), remember_me: true}
      )

    conn = submit_form(form, conn)

    assert redirected_to(conn) == ~p"/"
    assert conn.resp_cookies["_sakusen_web_user_remember_me"]
  end

  test "redirects back with an error on invalid credentials", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/users/log-in")

    form = form(lv, "#login_form", user: %{username: "nobody", password: "123456"})
    render_submit(form)
    conn = follow_trigger_action(form, conn)

    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid username or password"
    assert redirected_to(conn) == ~p"/users/log-in"
  end

  test "prefills the username when re-authenticating", %{conn: conn} do
    user = user_fixture()
    {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/users/log-in")

    assert html =~ "You need to reauthenticate"
    assert html =~ ~s(value="#{user.username}")
  end
end
