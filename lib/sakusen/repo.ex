defmodule Sakusen.Repo do
  use Ecto.Repo,
    otp_app: :sakusen,
    adapter: Ecto.Adapters.SQLite3
end
