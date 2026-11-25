defmodule Sakusen.Accounts.ProfileTest do
  use Sakusen.DataCase

  import Sakusen.AccountsFixtures

  alias Sakusen.Accounts
  alias Sakusen.Storage

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    on_exit(fn -> File.rm_rf!(Storage.Local.root()) end)

    path = Path.join(tmp_dir, "red.png")
    Image.write!(Image.new!(600, 400, color: :red), path)

    %{scope: user_scope_fixture(), path: path}
  end

  test "update_user_avatar/2 stores a 256x256 webp", %{scope: scope, path: path} do
    assert {:ok, user} = Accounts.update_user_avatar(scope, path)
    assert "avatar/" <> _ = user.avatar_key

    stored = Image.open!(Path.join(Storage.Local.root(), user.avatar_key))
    assert {256, 256, _bands} = Image.shape(stored)
  end
end
