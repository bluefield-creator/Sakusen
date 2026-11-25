defmodule Sakusen.SettingsTest do
  use Sakusen.DataCase

  import Sakusen.AccountsFixtures

  alias Sakusen.Settings

  @secret "s3cr3t-access-key"

  setup do
    admin_scope = user_scope_fixture()
    %{admin_scope: admin_scope, user_scope: user_scope_fixture()}
  end

  test "update_server_settings/2 stores the secret encrypted", %{admin_scope: admin_scope} do
    assert {:ok, _settings} =
             Settings.update_server_settings(admin_scope, %{
               "storage_backend" => "local",
               "s3_secret_access_key" => @secret
             })

    assert Settings.get_server_settings().s3_secret_access_key == @secret

    %{rows: [[stored]]} = Repo.query!("SELECT s3_secret_access_key FROM server_settings")
    refute stored =~ @secret
  end

  test "update_server_settings/2 rejects non-admins", %{user_scope: user_scope} do
    assert {:error, :unauthorized} =
             Settings.update_server_settings(user_scope, %{"storage_backend" => "local"})
  end
end
