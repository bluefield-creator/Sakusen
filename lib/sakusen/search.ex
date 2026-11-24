defmodule Sakusen.Search do
  @moduledoc "Post search: parses the search language and pages through matching posts."

  import Ecto.Query

  alias Sakusen.Repo
  alias Sakusen.Search.{Parser, QueryBuilder}

  @default_per_page 40

  defdelegate parse(input), to: Parser

  def search_posts(input, opts \\ []) do
    page = max(Keyword.get(opts, :page, 1), 1)
    per_page = Keyword.get(opts, :per_page, @default_per_page)

    with {:ok, query} <- parse(input) do
      posts =
        query
        |> QueryBuilder.build()
        |> limit(^(per_page + 1))
        |> offset(^((page - 1) * per_page))
        |> Repo.all()

      {:ok, %{posts: Enum.take(posts, per_page), page: page, has_next?: length(posts) > per_page}}
    end
  end
end
