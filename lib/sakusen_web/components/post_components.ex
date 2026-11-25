defmodule SakusenWeb.PostComponents do
  @moduledoc "Post markup shared across pages."

  use SakusenWeb, :html

  alias Sakusen.Posts.Media

  attr :post, :map, required: true

  def post_thumb(assigns) do
    ~H"""
    <li class="post-thumb" data-rating={@post.rating}>
      <.link navigate={~p"/posts/#{@post}"}>
        <img src={Media.thumbnail_url(@post)} alt={"Post #{@post.id}"} loading="lazy" />
      </.link>
    </li>
    """
  end
end
