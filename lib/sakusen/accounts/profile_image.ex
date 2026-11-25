defmodule Sakusen.Accounts.ProfileImage do
  @moduledoc "Avatar and banner processing: cropped webp images keyed by their SHA-256."

  @boxes %{avatar: "256x256", banner: "1500x500"}

  def process(kind, path) when is_map_key(@boxes, kind) do
    with {:ok, image} <- Image.open(path),
         {:ok, cropped} <- Image.thumbnail(image, Map.fetch!(@boxes, kind), crop: :center),
         {:ok, data} <- Image.write(cropped, :memory, suffix: ".webp") do
      {:ok, %{key: key(kind, data), data: data}}
    else
      _ -> {:error, :unsupported_format}
    end
  end

  defp key(kind, data) do
    sha256 = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    Sakusen.Posts.Media.shard_key(Atom.to_string(kind), sha256, "webp")
  end
end
