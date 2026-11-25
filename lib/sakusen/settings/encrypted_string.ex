defmodule Sakusen.Settings.EncryptedString do
  @moduledoc "Ecto type for strings stored encrypted with a key derived from the endpoint secret_key_base."

  use Ecto.Type

  alias Plug.Crypto.{KeyGenerator, MessageEncryptor}

  @encryption_salt "server settings encryption"
  @signing_salt "server settings signing"

  @impl true
  def type, do: :binary

  @impl true
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_value), do: :error

  @impl true
  def dump(value) when is_binary(value),
    do:
      {:ok,
       MessageEncryptor.encrypt(value, derive_key(@encryption_salt), derive_key(@signing_salt))}

  def dump(_value), do: :error

  @impl true
  def load(ciphertext) when is_binary(ciphertext),
    do:
      MessageEncryptor.decrypt(
        ciphertext,
        derive_key(@encryption_salt),
        derive_key(@signing_salt)
      )

  def load(_value), do: :error

  defp derive_key(salt) do
    KeyGenerator.generate(secret_key_base(), salt, cache: Plug.Crypto.Keys)
  end

  defp secret_key_base do
    Application.fetch_env!(:sakusen, SakusenWeb.Endpoint)[:secret_key_base]
  end
end
