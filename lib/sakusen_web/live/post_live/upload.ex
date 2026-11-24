defmodule SakusenWeb.PostLive.Upload do
  use SakusenWeb, :live_view

  alias Sakusen.Posts
  alias Sakusen.Posts.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="upload-panel">
        <.header>upload</.header>

        <.form for={@form} id="upload_form" phx-submit="save" phx-change="validate">
          <div class="dropzone" phx-drop-target={@uploads.file.ref}>
            <.live_file_input upload={@uploads.file} />

            <p :for={error <- upload_errors(@uploads.file)} class="field-error">
              {upload_error_message(error)}
            </p>
          </div>

          <figure :for={entry <- @uploads.file.entries} class="upload-preview">
            <.live_img_preview entry={entry} alt={entry.client_name} />
            <figcaption>
              {entry.client_name}
              <progress value={entry.progress} max="100">{entry.progress}%</progress>
              <button type="button" class="button" phx-click="cancel" phx-value-ref={entry.ref}>
                remove
              </button>
            </figcaption>
            <p :for={error <- upload_errors(@uploads.file, entry)} class="field-error">
              {upload_error_message(error)}
            </p>
          </figure>

          <p :if={@upload_error} class="field-error">{@upload_error}</p>

          <p :if={@duplicate} class="notice">
            already posted as
            <.link navigate={~p"/posts/#{@duplicate}"} class="bracketed">post #{@duplicate.id}</.link>
          </p>

          <.input field={@form[:rating]} type="select" label="rating" options={rating_options()} />
          <.input
            field={@form[:tags]}
            type="textarea"
            label="tags"
            placeholder="blue_sky artist:name"
            spellcheck="false"
          />
          <.input field={@form[:source]} type="url" label="source" placeholder="https://" />

          <.button phx-disable-with="uploading..." variant="primary">upload</.button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Upload", duplicate: nil, upload_error: nil)
     |> assign_form(Posts.change_post_metadata(%Post{rating: :general}))
     |> allow_upload(:file,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 50_000_000
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    post_params = Map.get(params, "post", %{})

    changeset =
      %Post{}
      |> Posts.change_post_metadata(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    changeset = Posts.change_post_metadata(%Post{}, post_params)

    if changeset.valid? do
      socket
      |> assign(duplicate: nil, upload_error: nil)
      |> create_post(post_params)
    else
      {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  defp create_post(socket, post_params) do
    results =
      consume_uploaded_entries(socket, :file, fn %{path: path}, _entry ->
        {:ok,
         Posts.create_post(socket.assigns.current_scope, %{
           path: path,
           rating: post_params["rating"],
           source: post_params["source"],
           tags: post_params["tags"]
         })}
      end)

    case results do
      [{:ok, post}] ->
        {:noreply,
         socket
         |> put_flash(:info, "post ##{post.id} uploaded")
         |> push_navigate(to: ~p"/posts/#{post}")}

      [{:error, {:duplicate, existing}}] ->
        {:noreply, assign(socket, duplicate: existing)}

      [{:error, :unsupported_format}] ->
        {:noreply, assign(socket, upload_error: upload_error_message(:not_accepted))}

      [{:error, _reason}] ->
        {:noreply, assign(socket, upload_error: "couldn't process file")}

      [] ->
        {:noreply, assign(socket, upload_error: "choose a file")}
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, form: to_form(changeset, as: "post"))

  defp rating_options do
    Enum.map(Post.ratings(), &{Atom.to_string(&1), &1})
  end

  defp upload_error_message(:too_large), do: "over 50 MB"
  defp upload_error_message(:not_accepted), do: "jpeg, png, gif or webp only"
  defp upload_error_message(:too_many_files), do: "one file at a time"
  defp upload_error_message(_error), do: "upload failed"
end
