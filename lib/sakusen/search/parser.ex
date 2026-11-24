defmodule Sakusen.Search.Parser do
  @moduledoc "Reads the search language into a `Sakusen.Search.Query`."

  alias Sakusen.Search.Query

  @max_tags 20

  @ratings %{
    "g" => :general,
    "general" => :general,
    "s" => :sensitive,
    "sensitive" => :sensitive,
    "q" => :questionable,
    "questionable" => :questionable,
    "e" => :explicit,
    "explicit" => :explicit
  }

  @orders %{
    "id" => :id_desc,
    "id_asc" => :id_asc,
    "width" => :width_desc,
    "height" => :height_desc,
    "filesize" => :file_size_desc
  }

  @numeric_fields %{"id" => :id, "width" => :width, "height" => :height, "filesize" => :file_size}

  @metatags ~w(rating user md5 order) ++ Map.keys(@numeric_fields)

  @size_units %{"" => 1, "kb" => 1024, "mb" => 1024 * 1024}

  def parse(input) when is_binary(input) do
    input
    |> String.split()
    |> Enum.reduce_while({:ok, %Query{}}, fn term, {:ok, query} ->
      case add_term(query, String.downcase(term)) do
        {:ok, query} -> {:cont, {:ok, query}}
        error -> {:halt, error}
      end
    end)
    |> within_tag_limit()
  end

  defp within_tag_limit({:ok, query}) do
    if Query.tag_count(query) > @max_tags,
      do: {:error, "Too many tags: at most #{@max_tags} allowed"},
      else: {:ok, query}
  end

  defp within_tag_limit(error), do: error

  defp add_term(query, "-" <> term), do: add_negated(query, term)
  defp add_term(query, "~" <> term), do: add_alternative(query, term)
  defp add_term(query, term), do: add_required(query, term)

  defp add_required(query, ""), do: {:ok, query}

  defp add_required(query, term) do
    case metatag(term) do
      {"order", value} ->
        with {:ok, order} <- order(value), do: {:ok, %{query | order: order}}

      {key, value} ->
        with {:ok, condition} <- condition(key, value), do: {:ok, add_condition(query, condition)}

      nil ->
        {:ok, %{query | required_tags: [tag_match(term) | query.required_tags]}}
    end
  end

  defp add_negated(query, ""), do: {:ok, query}

  defp add_negated(query, term) do
    case metatag(term) do
      {"order", _} ->
        {:error, "order: cannot be negated"}

      {key, value} ->
        with {:ok, condition} <- condition(key, value),
             do: {:ok, add_condition(query, {:not, condition})}

      nil ->
        {:ok, %{query | excluded_tags: [tag_match(term) | query.excluded_tags]}}
    end
  end

  defp add_alternative(query, ""), do: {:ok, query}

  defp add_alternative(query, term) do
    case metatag(term) do
      {key, _} -> {:error, "#{key}: cannot be used in a ~ group"}
      nil -> {:ok, %{query | any_tags: [tag_match(term) | query.any_tags]}}
    end
  end

  defp add_condition(query, condition), do: %{query | conditions: [condition | query.conditions]}

  defp metatag(term) do
    case String.split(term, ":", parts: 2) do
      [key, value] when key in @metatags -> {key, value}
      _ -> nil
    end
  end

  defp tag_match(term) do
    if String.contains?(term, "*"), do: {:pattern, term}, else: {:name, term}
  end

  defp order(value) do
    case Map.fetch(@orders, value) do
      {:ok, order} -> {:ok, order}
      :error -> invalid("order", value)
    end
  end

  defp condition("rating", value) do
    case Map.fetch(@ratings, value) do
      {:ok, rating} -> {:ok, {:rating, rating}}
      :error -> invalid("rating", value)
    end
  end

  defp condition("user", value) do
    if Regex.match?(~r/^[a-z0-9_]+$/, value),
      do: {:ok, {:uploader, value}},
      else: invalid("user", value)
  end

  defp condition("md5", value) do
    if Regex.match?(~r/^[0-9a-f]{32}$/, value),
      do: {:ok, {:md5, value}},
      else: invalid("md5", value)
  end

  defp condition("filesize" = key, value), do: compare(key, value, &file_size/1)
  defp condition(key, value), do: compare(key, value, &count/1)

  defp compare(key, value, parse_number) do
    case comparison(value, parse_number) do
      {:ok, comparison} -> {:ok, {:compare, @numeric_fields[key], comparison}}
      :error -> invalid(key, value)
    end
  end

  defp comparison(">=" <> n, parse), do: with({:ok, v} <- parse.(n), do: {:ok, {:gte, v}})
  defp comparison("<=" <> n, parse), do: with({:ok, v} <- parse.(n), do: {:ok, {:lte, v}})
  defp comparison(">" <> n, parse), do: with({:ok, v} <- parse.(n), do: {:ok, {:gt, v}})
  defp comparison("<" <> n, parse), do: with({:ok, v} <- parse.(n), do: {:ok, {:lt, v}})

  defp comparison(value, parse) do
    case String.split(value, "..", parts: 2) do
      [low, high] ->
        with {:ok, low} <- parse.(low),
             {:ok, high} <- parse.(high),
             do: {:ok, {:between, low, high}}

      [n] ->
        with {:ok, v} <- parse.(n), do: {:ok, {:eq, v}}
    end
  end

  defp count(text) do
    case Integer.parse(text) do
      {n, ""} when n >= 0 -> {:ok, n}
      _ -> :error
    end
  end

  defp file_size(text) do
    with {n, unit} when n >= 0 <- Float.parse(text),
         {:ok, multiplier} <- Map.fetch(@size_units, unit) do
      {:ok, trunc(n * multiplier)}
    else
      _ -> :error
    end
  end

  defp invalid(key, value), do: {:error, "Invalid value for #{key}: #{inspect(value)}"}
end
