defmodule SakusenWeb.PageControllerTest do
  use SakusenWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Sakusen"
  end
end
