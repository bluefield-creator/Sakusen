defmodule Sakusen.Settings do
  @moduledoc "Instance-wide server settings, including where media is stored."

  import Ecto.Query, warn: false

  alias Sakusen.Accounts.Scope
  alias Sakusen.Repo
  alias Sakusen.Settings.ServerSettings
  alias Sakusen.Storage

  @storage_cache_key {__MODULE__, :storage}
  @probe_body "sakusen storage probe"

  def get_server_settings do
    ServerSettings |> first() |> Repo.one() || %ServerSettings{}
  end

  def change_server_settings(%ServerSettings{} = settings, attrs \\ %{}) do
    ServerSettings.changeset(settings, attrs)
  end

  def update_server_settings(%Scope{} = scope, attrs) do
    if Scope.admin?(scope) do
      with {:ok, settings} <-
             get_server_settings()
             |> ServerSettings.changeset(attrs)
             |> Repo.insert_or_update() do
        cache_storage(settings)
        {:ok, settings}
      end
    else
      {:error, :unauthorized}
    end
  end

  def storage do
    case :persistent_term.get(@storage_cache_key, nil) do
      nil -> cache_storage(get_server_settings())
      storage -> storage
    end
  end

  def clear_storage_cache do
    :persistent_term.erase(@storage_cache_key)
    :ok
  end

  def test_storage(attrs) do
    with {:ok, settings} <-
           get_server_settings()
           |> ServerSettings.changeset(attrs)
           |> Ecto.Changeset.apply_action(:validate) do
      config = storage_config(settings)
      key = "probe/#{Ecto.UUID.generate()}.txt"

      with :ok <- Storage.put(config, key, {:data, @probe_body}, "text/plain") do
        Storage.delete(config, key)
      end
    end
  end

  defp cache_storage(settings) do
    storage = storage_config(settings)
    :persistent_term.put(@storage_cache_key, storage)
    storage
  end

  defp storage_config(%ServerSettings{storage_backend: :s3} = settings) do
    %{
      backend: :s3,
      endpoint: settings.s3_endpoint,
      region: settings.s3_region,
      bucket: settings.s3_bucket,
      access_key_id: settings.s3_access_key_id,
      secret_access_key: settings.s3_secret_access_key,
      public_url: settings.s3_public_url
    }
  end

  defp storage_config(%ServerSettings{}), do: %{backend: :local}
end
