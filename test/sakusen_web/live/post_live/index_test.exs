defmodule SakusenWeb.PostLive.IndexTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sakusen.PostsFixtures

  test "searching filters the grid", %{conn: conn} do
    cat = post_fixture(tags: "cat")
    dog = post_fixture(tags: "dog")

    {:ok, lv, _html} = live(conn, ~p"/")
    assert has_element?(lv, ".post-thumb a[href='/posts/#{dog.id}']")

    lv |> form(".search-bar", %{tags: "cat"}) |> render_submit()

    assert_patch(lv, ~p"/?tags=cat")
    assert has_element?(lv, ".post-thumb a[href='/posts/#{cat.id}']")
    refute has_element?(lv, ".post-thumb a[href='/posts/#{dog.id}']")
  end
end
