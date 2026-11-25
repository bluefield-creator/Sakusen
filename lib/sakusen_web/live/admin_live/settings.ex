defmodule SakusenWeb.AdminLive.Settings do
  use SakusenWeb, :live_view

  on_mount {SakusenWeb.UserAuth, :require_admin}

  alias Sakusen.Settings
  alias Sakusen.Settings.ServerSettings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="upload-panel">
        <.header>server settings</.header>

        <p class="notice">switching storage doesn't move files already stored</p>

        <.form for={@form} id="server_settings_form" phx-change="validate" phx-submit="save">
          <.input
            field={@form[:storage_backend]}
            type="select"
            label="storage"
            options={storage_backend_options()}
          />

          <%= if @s3? do %>
            <.input
              field={@form[:s3_endpoint]}
              type="url"
              label="endpoint"
              placeholder="https://s3.example.com"
              spellcheck="false"
            />
            <.input field={@form[:s3_region]} type="text" label="region" spellcheck="false" />
            <.input field={@form[:s3_bucket]} type="text" label="bucket" spellcheck="false" />
            <.input
              field={@form[:s3_access_key_id]}
              type="text"
              label="access key id"
              autocomplete="off"
              spellcheck="false"
            />
            <.input
              field={@form[:s3_secret_access_key]}
              type="password"
              label="secret access key"
              value={@typed_secret}
              placeholder={@secret_stored? && "stored"}
              autocomplete="new-password"
              spellcheck="false"
            />
            <.input
              field={@form[:s3_public_url]}
              type="url"
              label="public url"
              placeholder="https://media.example.com"
              spellcheck="false"
            />
          <% end %>

          <button
            type="button"
            id="test_storage"
            class="button"
            phx-click="test_storage"
            phx-disable-with="testing..."
          >
            test connection
          </button>
          <.button variant="primary" phx-disable-with="saving...">save</.button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    settings = Settings.get_server_settings()

    {:ok,
     socket
     |> assign(page_title: "Server settings")
     |> assign_settings(settings)}
  end

  @impl true
  def handle_event("validate", %{"server_settings" => params}, socket) do
    changeset =
      socket.assigns.settings
      |> Settings.change_server_settings(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"server_settings" => params}, socket) do
    case Settings.update_server_settings(socket.assigns.current_scope, params) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> put_flash(:info, "settings saved")
         |> assign_settings(settings)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "admins only")}
    end
  end

  def handle_event("test_storage", _params, socket) do
    case Settings.test_storage(socket.assigns.form.params) do
      :ok ->
        {:noreply, put_flash(socket, :info, "storage works")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "fix the fields first")
         |> assign_form(Map.put(changeset, :action, :validate))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "storage failed: #{failure_message(reason)}")}
    end
  end

  defp assign_settings(socket, settings) do
    socket
    |> assign(:settings, settings)
    |> assign_form(Settings.change_server_settings(settings))
  end

  defp assign_form(socket, changeset) do
    assign(socket,
      form: to_form(changeset),
      s3?: Ecto.Changeset.get_field(changeset, :storage_backend) == :s3,
      typed_secret: Ecto.Changeset.get_change(changeset, :s3_secret_access_key),
      secret_stored?: not is_nil(changeset.data.s3_secret_access_key)
    )
  end

  defp storage_backend_options do
    Enum.map(ServerSettings.storage_backends(), &{storage_backend_label(&1), &1})
  end

  defp storage_backend_label(:local), do: "local disk"
  defp storage_backend_label(:s3), do: "s3 bucket"

  defp failure_message({:http_status, status}), do: "bucket answered #{status}"
  defp failure_message(%{__exception__: true} = exception), do: Exception.message(exception)
  defp failure_message(reason), do: inspect(reason)
end
