defmodule SakusenWeb.PostLive.Show do
  use SakusenWeb, :live_view

  alias Sakusen.Posts
  alias Sakusen.Posts.Storage
  alias Sakusen.Tags

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="post-layout">
        <aside class="post-sidebar">
          <section :for={{category, tags} <- @tag_groups} class="tag-list">
            <h2>{category}</h2>
            <ul>
              <li :for={tag <- tags} class={"tag tag--#{category}"}>
                <.link navigate={~p"/?#{[tags: tag.name]}"}>{tag.name}</.link>
                <span class="tag-count">{tag.post_count}</span>
              </li>
            </ul>
          </section>

          <dl class="post-info">
            <dt>id</dt>
            <dd>{@post.id}</dd>
            <dt>by</dt>
            <dd>
              <.link
                :if={@post.uploader}
                navigate={~p"/?#{[tags: "user:" <> @post.uploader.username]}"}
              >
                {@post.uploader.username}
              </.link>
            </dd>
            <dt>date</dt>
            <dd>
              <time datetime={DateTime.to_iso8601(@post.inserted_at)}>
                {Calendar.strftime(@post.inserted_at, "%Y-%m-%d %H:%M")}
              </time>
            </dd>
            <dt>file</dt>
            <dd>{human_file_size(@post.file_size)}</dd>
            <dt>size</dt>
            <dd>{@post.width}×{@post.height}</dd>
            <dt>rating</dt>
            <dd>{@post.rating}</dd>
            <dt>source</dt>
            <dd>
              <a :if={web_url?(@post.source)} href={@post.source} rel="noopener noreferrer nofollow">
                {@post.source}
              </a>
              <span :if={!web_url?(@post.source)}>{@post.source}</span>
            </dd>
            <dt>md5</dt>
            <dd>{@post.md5}</dd>
          </dl>
        </aside>

        <figure class="post-media">
          <a href={Storage.original_url(@post)}>
            <img
              src={Storage.original_url(@post)}
              alt={Enum.map_join(@post.tags, " ", & &1.name)}
              width={@post.width}
              height={@post.height}
            />
          </a>
        </figure>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Posts.get_post!(id)

    {:ok,
     assign(socket,
       page_title: "post ##{post.id}",
       post: post,
       tag_groups: Tags.tags_by_category(post)
     )}
  end

  @kibibyte 1024
  @mebibyte 1024 * 1024

  defp human_file_size(bytes) when bytes >= @mebibyte,
    do: "#{Float.round(bytes / @mebibyte, 2)} MB"

  defp human_file_size(bytes), do: "#{Float.round(bytes / @kibibyte, 1)} KB"

  defp web_url?(nil), do: false
  defp web_url?(source), do: URI.parse(source).scheme in ["http", "https"]
end
