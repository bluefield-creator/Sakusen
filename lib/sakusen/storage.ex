defmodule Sakusen.Storage do
  @moduledoc "Puts, deletes and links media objects on the configured storage backend."

  alias Sakusen.Settings
  alias Sakusen.Storage.{Local, S3}

  @type config ::
          %{backend: :local}
          | %{
              backend: :s3,
              endpoint: String.t(),
              region: String.t(),
              bucket: String.t(),
              access_key_id: String.t(),
              secret_access_key: String.t(),
              public_url: String.t()
            }
  @type key :: String.t()
  @type source :: {:path, Path.t()} | {:data, binary()}

  @callback put(config(), key(), source(), content_type :: String.t()) :: :ok | {:error, term()}
  @callback delete(config(), key()) :: :ok | {:error, term()}
  @callback url(config(), key()) :: String.t()

  @spec put(key(), source(), String.t()) :: :ok | {:error, term()}
  def put(key, source, content_type), do: put(Settings.storage(), key, source, content_type)

  @spec put(config(), key(), source(), String.t()) :: :ok | {:error, term()}
  def put(config, key, source, content_type),
    do: backend(config).put(config, key, source, content_type)

  @spec delete(key()) :: :ok | {:error, term()}
  def delete(key), do: delete(Settings.storage(), key)

  @spec delete(config(), key()) :: :ok | {:error, term()}
  def delete(config, key), do: backend(config).delete(config, key)

  @spec url(key()) :: String.t()
  def url(key), do: url(Settings.storage(), key)

  @spec url(config(), key()) :: String.t()
  def url(config, key), do: backend(config).url(config, key)

  defp backend(%{backend: :local}), do: Local
  defp backend(%{backend: :s3}), do: S3
end
