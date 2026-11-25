defmodule Sakusen.Storage.S3 do
  @moduledoc "Stores media objects in an S3-compatible bucket, served from its public base URL."

  @behaviour Sakusen.Storage

  @immutable_cache_control "public, max-age=31536000, immutable"

  @impl true
  def put(config, key, source, content_type) do
    config
    |> object_request(key)
    |> Req.put(
      body: body(source),
      headers: [content_type: content_type, cache_control: @immutable_cache_control]
    )
    |> result()
  end

  @impl true
  def delete(config, key) do
    config
    |> object_request(key)
    |> Req.delete()
    |> result()
  end

  @impl true
  def url(%{public_url: public_url}, key), do: String.trim_trailing(public_url, "/") <> "/" <> key

  defp object_request(config, key) do
    Req.new(
      url: Enum.join([String.trim_trailing(config.endpoint, "/"), config.bucket, key], "/"),
      aws_sigv4: [
        service: :s3,
        region: config.region,
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key
      ]
    )
    |> Req.merge(extra_req_options())
  end

  defp extra_req_options do
    Application.get_env(:sakusen, __MODULE__, [])[:req_options] || []
  end

  defp body({:path, path}), do: File.read!(path)
  defp body({:data, data}), do: data

  defp result({:ok, %Req.Response{status: status}}) when status in 200..299, do: :ok
  defp result({:ok, %Req.Response{status: status}}), do: {:error, {:http_status, status}}
  defp result({:error, exception}), do: {:error, exception}
end
