defmodule SakusenWeb.UserLive.ProfileTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.AccountsFixtures

  test "renders the profile of an existing user", %{conn: conn} do
    user = user_fixture()

    {:ok, lv, _html} = live(conn, ~p"/u/#{user.username}")

    assert has_element?(lv, "#profile")
  end
end
