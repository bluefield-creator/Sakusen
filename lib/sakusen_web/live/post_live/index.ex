defmodule SakusenWeb.PostLive.Index do
  use SakusenWeb, :live_view

  alias Sakusen.Posts.Storage
  alias Sakusen.Search

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <form class="search-bar" phx-submit="search" role="search">
        <label for="search-tags" class="visually-hidden">Search tags</label>
        <input
          id="search-tags"
          type="search"
          name="tags"
          value={@query}
          autocomplete="off"
          spellcheck="false"
        />
        <.button variant="primary">Search</.button>
      </form>

      <p :if={@error} class="search-error" role="alert">{@error}</p>

      <ul class="post-grid">
        <li :for={post <- @posts} class="post-thumb" data-rating={post.rating}>
          <.link navigate={~p"/posts/#{post}"}>
            <img src={Storage.thumbnail_url(post)} alt={"Post #{post.id}"} loading="lazy" />
          </.link>
        </li>
      </ul>

      <p :if={@posts == [] and !@error} class="empty-state">No posts match.</p>

      <nav class="pager" aria-label="Pages">
        <.link :if={@page > 1} patch={search_path(@query, @page - 1)} rel="prev">Previous</.link>
        <span class="pager-current">Page {@page}</span>
        <.link :if={@has_next?} patch={search_path(@query, @page + 1)} rel="next">Next</.link>
      </nav>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _uri, socket) do
    query = String.trim(params["tags"] || "")
    page = page_number(params["page"])

    socket =
      socket
      |> assign(query: query, page_title: if(query == "", do: "Posts", else: query))
      |> assign_results(Search.search_posts(query, page: page), page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"tags" => tags}, socket) do
    {:noreply, push_patch(socket, to: search_path(String.trim(tags), 1))}
  end

  defp assign_results(socket, {:ok, results}, _page) do
    assign(socket,
      posts: results.posts,
      page: results.page,
      has_next?: results.has_next?,
      error: nil
    )
  end

  defp assign_results(socket, {:error, message}, page) do
    assign(socket, posts: [], page: page, has_next?: false, error: message)
  end

  defp page_number(param) do
    case Integer.parse(param || "") do
      {page, ""} when page > 0 -> page
      _ -> 1
    end
  end

  defp search_path(query, page) do
    params = Enum.reject([tags: query, page: page], &(&1 in [tags: "", page: 1]))
    ~p"/?#{params}"
  end
end
