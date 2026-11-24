defmodule Sakusen.Search.QueryBuilder do
  @moduledoc "Turns a `Sakusen.Search.Query` into an Ecto query over posts."

  import Ecto.Query

  alias Sakusen.Accounts.User
  alias Sakusen.Posts.Post
  alias Sakusen.Search.Query
  alias Sakusen.Tags.{PostTag, Tag}

  @orderings %{
    id_desc: [desc: :id],
    id_asc: [asc: :id],
    width_desc: [desc: :width, desc: :id],
    height_desc: [desc: :height, desc: :id],
    file_size_desc: [desc: :file_size, desc: :id]
  }

  def build(%Query{} = query) do
    ordering = Map.fetch!(@orderings, query.order)

    query
    |> constraints()
    |> Enum.reduce(from(p in Post, as: :post), fn constraint, posts ->
      where(posts, ^constraint)
    end)
    |> order_by(^ordering)
  end

  defp constraints(query) do
    Enum.map(query.required_tags, fn match -> dynamic(exists(tagged_with([match]))) end) ++
      Enum.map(query.excluded_tags, fn match -> dynamic(not exists(tagged_with([match]))) end) ++
      any_tags_constraint(query.any_tags) ++
      Enum.map(query.conditions, &condition/1)
  end

  defp any_tags_constraint([]), do: []
  defp any_tags_constraint(matches), do: [dynamic(exists(tagged_with(matches)))]

  defp tagged_with(matches) do
    from pt in PostTag,
      join: t in Tag,
      on: t.id == pt.tag_id,
      where: pt.post_id == parent_as(:post).id,
      where: ^any_tag_matches(matches),
      select: 1
  end

  defp any_tag_matches(matches) do
    matches
    |> Enum.map(&tag_matches/1)
    |> Enum.reduce(fn match, matches -> dynamic(^matches or ^match) end)
  end

  defp tag_matches({:name, name}), do: dynamic([_pt, t], t.name == ^name)

  defp tag_matches({:pattern, pattern}),
    do: dynamic([_pt, t], fragment("? LIKE ? ESCAPE '\\'", t.name, ^like_pattern(pattern)))

  defp like_pattern(pattern) do
    pattern
    |> String.split("*")
    |> Enum.map_join("%", &String.replace(&1, ["\\", "%", "_"], fn char -> "\\" <> char end))
  end

  defp condition({:not, condition}), do: dynamic(not (^condition(condition)))
  defp condition({:rating, rating}), do: dynamic([post: p], p.rating == ^rating)
  defp condition({:md5, md5}), do: dynamic([post: p], p.md5 == ^md5)

  defp condition({:uploader, username}) do
    uploader =
      from u in User,
        where: u.id == parent_as(:post).uploader_id and u.username == ^username,
        select: 1

    dynamic(exists(uploader))
  end

  defp condition({:compare, field, comparison}), do: compare(field, comparison)

  defp compare(field, {:eq, n}), do: dynamic([post: p], field(p, ^field) == ^n)
  defp compare(field, {:gt, n}), do: dynamic([post: p], field(p, ^field) > ^n)
  defp compare(field, {:gte, n}), do: dynamic([post: p], field(p, ^field) >= ^n)
  defp compare(field, {:lt, n}), do: dynamic([post: p], field(p, ^field) < ^n)
  defp compare(field, {:lte, n}), do: dynamic([post: p], field(p, ^field) <= ^n)

  defp compare(field, {:between, low, high}),
    do: dynamic([post: p], field(p, ^field) >= ^low and field(p, ^field) <= ^high)
end
