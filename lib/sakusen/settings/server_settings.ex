defmodule Sakusen.Settings.ServerSettings do
  @moduledoc "The single row of instance-wide settings, such as the media storage backend."

  use Ecto.Schema
  import Ecto.Changeset

  alias Sakusen.Settings.EncryptedString

  @s3_fields [
    :s3_endpoint,
    :s3_region,
    :s3_bucket,
    :s3_access_key_id,
    :s3_secret_access_key,
    :s3_public_url
  ]

  schema "server_settings" do
    field :storage_backend, Ecto.Enum, values: [:local, :s3], default: :local
    field :s3_endpoint, :string
    field :s3_region, :string
    field :s3_bucket, :string
    field :s3_access_key_id, :string
    field :s3_secret_access_key, EncryptedString, redact: true
    field :s3_public_url, :string

    timestamps(type: :utc_datetime)
  end

  def storage_backends, do: Ecto.Enum.values(__MODULE__, :storage_backend)

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:storage_backend | @s3_fields])
    |> keep_stored_secret_when_blank()
    |> validate_required([:storage_backend])
    |> validate_http_url(:s3_endpoint)
    |> validate_http_url(:s3_public_url)
    |> validate_s3_complete()
  end

  defp keep_stored_secret_when_blank(changeset) do
    case fetch_change(changeset, :s3_secret_access_key) do
      {:ok, nil} -> delete_change(changeset, :s3_secret_access_key)
      _ -> changeset
    end
  end

  defp validate_http_url(changeset, field) do
    validate_change(changeset, field, fn ^field, url ->
      case URI.parse(url) do
        %URI{scheme: scheme, host: host}
        when scheme in ["http", "https"] and host not in [nil, ""] ->
          []

        _ ->
          [{field, "must be an http(s) url"}]
      end
    end)
  end

  defp validate_s3_complete(changeset) do
    if get_field(changeset, :storage_backend) == :s3 do
      validate_required(changeset, @s3_fields)
    else
      changeset
    end
  end
end
