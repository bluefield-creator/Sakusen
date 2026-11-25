defmodule SakusenWeb.AdminLiveTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.AccountsFixtures

  setup context do
    _admin = user_fixture()
    register_and_log_in_user(context)
  end

  test "redirects non-admins away from server settings", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/settings")
  end
end
