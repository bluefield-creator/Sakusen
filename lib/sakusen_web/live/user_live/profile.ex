defmodule SakusenWeb.UserLive.Profile do
  use SakusenWeb, :live_view

  import SakusenWeb.PostComponents

  alias Sakusen.Accounts
  alias Sakusen.Posts
  alias Sakusen.Search

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div id="profile">
        <img :if={@banner_url} src={@banner_url} alt="" class="profile-banner" />

        <div class="post-layout">
          <aside class="post-sidebar">
            <img :if={@avatar_url} src={@avatar_url} alt="" class="avatar" />

            <.header>{@user.display_name || @user.username}</.header>

            <dl class="post-info">
              <dt>username</dt>
              <dd>{@user.username}</dd>
              <dt>joined</dt>
              <dd>
                <time datetime={DateTime.to_iso8601(@user.inserted_at)}>
                  {Calendar.strftime(@user.inserted_at, "%Y-%m-%d %H:%M")}
                </time>
              </dd>
              <dt>posts</dt>
              <dd>{@post_count}</dd>
              <dt :if={@user.bio}>bio</dt>
              <dd :if={@user.bio} class="profile-bio">{@user.bio}</dd>
            </dl>
          </aside>

          <section>
            <ul class="post-grid">
              <.post_thumb :for={post <- @posts} post={post} />
            </ul>

            <p :if={@posts == []} class="empty-state">nothing yet</p>

            <nav :if={@posts != []} class="pager" aria-label="Posts">
              <.link navigate={~p"/?#{[tags: "user:" <> @user.username]}"} class="bracketed">
                all posts
              </.link>
            </nav>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    user = Accounts.get_user_by_username!(username)
    {:ok, %{posts: posts}} = Search.search_posts("user:" <> user.username, page: 1)

    {:ok,
     assign(socket,
       page_title: user.username,
       user: user,
       avatar_url: Accounts.avatar_url(user),
       banner_url: Accounts.banner_url(user),
       post_count: Posts.count_posts_by_uploader(user),
       posts: posts
     )}
  end
end
