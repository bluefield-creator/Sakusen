defmodule SakusenWeb.PostLive.UploadTest do
  use SakusenWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders the upload form", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/upload")

    assert has_element?(lv, "#upload_form")
  end
end
