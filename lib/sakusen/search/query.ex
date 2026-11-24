defmodule Sakusen.Search.Query do
  @moduledoc "A parsed post search: tag constraints, metatag conditions and ordering."

  @type tag_match :: {:name, String.t()} | {:pattern, String.t()}
  @type comparison ::
          {:eq, integer}
          | {:gt, integer}
          | {:gte, integer}
          | {:lt, integer}
          | {:lte, integer}
          | {:between, integer, integer}
  @type condition ::
          {:rating, atom}
          | {:uploader, String.t()}
          | {:md5, String.t()}
          | {:compare, :id | :width | :height | :file_size, comparison}
          | {:not, condition}
  @type order :: :id_desc | :id_asc | :width_desc | :height_desc | :file_size_desc

  @type t :: %__MODULE__{
          required_tags: [tag_match],
          excluded_tags: [tag_match],
          any_tags: [tag_match],
          conditions: [condition],
          order: order
        }

  defstruct required_tags: [], excluded_tags: [], any_tags: [], conditions: [], order: :id_desc

  def tag_count(%__MODULE__{} = query) do
    length(query.required_tags) + length(query.excluded_tags) + length(query.any_tags)
  end
end
