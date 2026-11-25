defmodule Sakusen.Storage.Local do
  @moduledoc "Stores media objects on the local filesystem under the media root, served at /media."

  @behaviour Sakusen.Storage

  def root, do: Application.fetch_env!(:sakusen, :media_root)

  @impl true
  def put(_config, key, source, _content_type) do
    destination = path(key)

    with :ok <- File.mkdir_p(Path.dirname(destination)) do
      write(source, destination)
    end
  end

  @impl true
  def delete(_config, key) do
    case File.rm(path(key)) do
      {:error, :enoent} -> :ok
      result -> result
    end
  end

  @impl true
  def url(_config, key), do: "/media/" <> key

  defp path(key), do: Path.join(root(), key)

  defp write({:path, source_path}, destination), do: File.cp(source_path, destination)
  defp write({:data, data}, destination), do: File.write(destination, data)
end
