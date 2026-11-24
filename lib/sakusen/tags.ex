defmodule Sakusen.Tags do
  @moduledoc "Tag vocabulary: reading tag input and maintaining each post's tag set."

  import Ecto.Query

  alias Sakusen.Posts.Post
  alias Sakusen.Repo
  alias Sakusen.Tags.{PostTag, Tag}

  @categories_by_name Map.new(Tag.categories(), &{Atom.to_string(&1), &1})

  def parse_tag_input(input) when is_binary(input) do
    entries =
      input
      |> String.split()
      |> Enum.map(&(&1 |> String.downcase() |> parse_token()))
      |> Enum.filter(&valid_name?(elem(&1, 0)))

    categories = for {name, category} <- entries, category, into: %{}, do: {name, category}

    entries
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
    |> Enum.map(&{&1, categories[&1]})
  end

  defp parse_token(token) do
    case String.split(token, ":", parts: 2) do
      [prefix, name] when is_map_key(@categories_by_name, prefix) ->
        {name, @categories_by_name[prefix]}

      _ ->
        {token, nil}
    end
  end

  defp valid_name?(""), do: false
  defp valid_name?("-" <> _), do: false
  defp valid_name?("~" <> _), do: false
  defp valid_name?(name), do: not String.contains?(name, "*")

  def put_post_tags(%Post{id: post_id}, tag_input) do
    entries = parse_tag_input(tag_input)

    Repo.transaction(fn ->
      case upsert_tags(entries) do
        {:ok, tags} -> replace_post_tags(post_id, Enum.map(tags, & &1.id))
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp upsert_tags(entries) do
    names = Enum.map(entries, &elem(&1, 0))
    existing = Repo.all(from t in Tag, where: t.name in ^names) |> Map.new(&{&1.name, &1})

    Enum.reduce_while(entries, {:ok, []}, fn {name, category}, {:ok, tags} ->
      case upsert_tag(existing[name], name, category) do
        {:ok, tag} -> {:cont, {:ok, [tag | tags]}}
        error -> {:halt, error}
      end
    end)
  end

  defp upsert_tag(nil, name, category) do
    %Tag{}
    |> Tag.changeset(%{name: name, category: category || :general})
    |> Repo.insert()
  end

  defp upsert_tag(tag, _name, nil), do: {:ok, tag}
  defp upsert_tag(%Tag{category: category} = tag, _name, category), do: {:ok, tag}

  defp upsert_tag(tag, _name, category),
    do: tag |> Tag.changeset(%{category: category}) |> Repo.update()

  defp replace_post_tags(post_id, tag_ids) do
    current_ids = Repo.all(from pt in PostTag, where: pt.post_id == ^post_id, select: pt.tag_id)
    added = tag_ids -- current_ids
    removed = current_ids -- tag_ids

    Repo.delete_all(from pt in PostTag, where: pt.post_id == ^post_id and pt.tag_id in ^removed)
    Repo.insert_all(PostTag, Enum.map(added, &%{post_id: post_id, tag_id: &1}))
    change_post_count(added, 1)
    change_post_count(removed, -1)

    Repo.all(from t in Tag, where: t.id in ^tag_ids, order_by: t.name)
  end

  defp change_post_count([], _delta), do: :ok

  defp change_post_count(tag_ids, delta) do
    Repo.update_all(from(t in Tag, where: t.id in ^tag_ids), inc: [post_count: delta])
  end

  def tags_by_category(%Post{id: post_id}) do
    by_category =
      Repo.all(
        from t in Tag,
          join: pt in PostTag,
          on: pt.tag_id == t.id,
          where: pt.post_id == ^post_id,
          order_by: t.name
      )
      |> Enum.group_by(& &1.category)

    for category <- Tag.categories(), Map.has_key?(by_category, category) do
      {category, by_category[category]}
    end
  end
end
