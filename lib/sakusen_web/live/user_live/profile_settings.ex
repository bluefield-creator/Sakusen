defmodule SakusenWeb.UserLive.ProfileSettings do
  use SakusenWeb, :live_view

  alias Sakusen.Accounts
  alias Sakusen.Accounts.Scope

  @image_uploads [avatar: &Accounts.update_user_avatar/2, banner: &Accounts.update_user_banner/2]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="upload-panel">
        <.header>
          profile
          <:actions>
            <.link navigate={~p"/u/#{@current_scope.user.username}"} class="bracketed">view</.link>
          </:actions>
        </.header>

        <.form for={@form} id="profile_form" phx-submit="save" phx-change="validate">
          <.input field={@form[:display_name]} type="text" label="display name" />
          <.input field={@form[:bio]} type="textarea" label="bio" />

          <.image_upload upload={@uploads.avatar} label="avatar" current_url={@avatar_url} />
          <.image_upload upload={@uploads.banner} label="banner" current_url={@banner_url} />

          <p :if={@upload_error} class="field-error">{@upload_error}</p>

          <.button phx-disable-with="saving..." variant="primary">save</.button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :label, :string, required: true
  attr :current_url, :string, default: nil

  defp image_upload(assigns) do
    ~H"""
    <div class="field">
      <label for={@upload.ref}>{@label}</label>

      <figure :if={@current_url && @upload.entries == []} class="upload-preview">
        <img src={@current_url} alt={"current #{@label}"} />
      </figure>

      <div class="dropzone" phx-drop-target={@upload.ref}>
        <.live_file_input upload={@upload} />

        <p :for={error <- upload_errors(@upload)} class="field-error">
          {upload_error_message(error)}
        </p>
      </div>

      <figure :for={entry <- @upload.entries} class="upload-preview">
        <.live_img_preview entry={entry} alt={entry.client_name} />
        <figcaption>
          {entry.client_name}
          <progress value={entry.progress} max="100">{entry.progress}%</progress>
          <button
            type="button"
            class="button"
            phx-click="cancel"
            phx-value-upload={@upload.name}
            phx-value-ref={entry.ref}
          >
            remove
          </button>
        </figcaption>
        <p :for={error <- upload_errors(@upload, entry)} class="field-error">
          {upload_error_message(error)}
        </p>
      </figure>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      Enum.reduce(Keyword.keys(@image_uploads), socket, fn name, socket ->
        allow_upload(socket, name,
          accept: ~w(.jpg .jpeg .png .gif .webp),
          max_entries: 1,
          max_file_size: 10_000_000
        )
      end)

    {:ok,
     socket
     |> assign(page_title: "Profile", upload_error: nil)
     |> assign_user(user)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(Map.get(params, "user", %{}))
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("cancel", %{"upload" => upload, "ref" => ref}, socket) do
    name = Enum.find(Keyword.keys(@image_uploads), &(Atom.to_string(&1) == upload))
    {:noreply, cancel_upload(socket, name, ref)}
  end

  def handle_event("save", params, socket) do
    scope = socket.assigns.current_scope

    case Accounts.update_user_profile(scope, Map.get(params, "user", %{})) do
      {:ok, user} ->
        socket
        |> assign(upload_error: nil)
        |> save_images(Scope.for_user(user))

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_images(socket, scope) do
    {scope, failures} =
      Enum.reduce(@image_uploads, {scope, []}, fn {name, update}, {scope, failures} ->
        case consume_uploaded_entries(socket, name, fn %{path: path}, _entry ->
               {:ok, update.(scope, path)}
             end) do
          [{:ok, user}] -> {Scope.for_user(user), failures}
          [{:error, _reason}] -> {scope, [name | failures]}
          [] -> {scope, failures}
        end
      end)

    socket =
      socket
      |> assign(current_scope: scope)
      |> assign_user(scope.user)

    case failures do
      [] ->
        {:noreply, put_flash(socket, :info, "profile saved")}

      failures ->
        {:noreply,
         assign(socket,
           upload_error: "couldn't process #{Enum.join(Enum.reverse(failures), ", ")}"
         )}
    end
  end

  defp assign_user(socket, user) do
    assign(socket,
      form: to_form(Accounts.change_user_profile(user)),
      avatar_url: Accounts.avatar_url(user),
      banner_url: Accounts.banner_url(user)
    )
  end

  defp upload_error_message(:too_large), do: "over 10 MB"
  defp upload_error_message(:not_accepted), do: "jpeg, png, gif or webp only"
  defp upload_error_message(:too_many_files), do: "one file at a time"
  defp upload_error_message(_error), do: "upload failed"
end
