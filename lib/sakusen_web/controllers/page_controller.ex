defmodule SakusenWeb.PageController do
  use SakusenWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
