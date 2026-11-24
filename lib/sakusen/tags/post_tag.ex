defmodule Sakusen.Tags.PostTag do
  use Ecto.Schema

  @primary_key false
  schema "post_tags" do
    belongs_to :post, Sakusen.Posts.Post, primary_key: true
    belongs_to :tag, Sakusen.Tags.Tag, primary_key: true
  end
end
