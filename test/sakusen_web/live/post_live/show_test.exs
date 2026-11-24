defmodule SakusenWeb.PostLive.ShowTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.PostsFixtures

  test "shows the post with its tags", %{conn: conn} do
    post = post_fixture(tags: "blue_sky")

    {:ok, _lv, html} = live(conn, ~p"/posts/#{post}")

    assert html =~ "blue_sky"
  end
end
