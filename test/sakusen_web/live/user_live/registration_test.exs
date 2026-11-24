defmodule SakusenWeb.UserLive.RegistrationTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.AccountsFixtures

  test "redirects if already logged in", %{conn: conn} do
    assert {:ok, _conn} =
             conn
             |> log_in_user(user_fixture())
             |> live(~p"/users/register")
             |> follow_redirect(conn, ~p"/")
  end

  test "registers and logs the user in", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/users/register")
    username = unique_username()

    form =
      form(lv, "#registration_form",
        user: %{
          username: username,
          password: valid_user_password(),
          password_confirmation: valid_user_password()
        }
      )

    render_submit(form)
    conn = follow_trigger_action(form, conn)

    assert get_session(conn, :user_token)
    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "welcome"
    assert Sakusen.Accounts.get_user_by_username(username)
  end

  test "renders errors for invalid data", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/users/register")

    result =
      lv
      |> element("#registration_form")
      |> render_change(user: %{"username" => "a!", "password" => "short"})

    assert result =~ "only letters, digits and underscores"
    assert result =~ "should be at least 12 character(s)"
  end

  test "renders errors for a taken username", %{conn: conn} do
    user = user_fixture()
    {:ok, lv, _html} = live(conn, ~p"/users/register")

    result =
      lv
      |> form("#registration_form", user: valid_user_attributes(username: user.username))
      |> render_submit()

    assert result =~ "has already been taken"
  end
end
