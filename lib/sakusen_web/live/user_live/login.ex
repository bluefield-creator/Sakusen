defmodule SakusenWeb.UserLive.Login do
  use SakusenWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="auth-panel">
        <.header>
          log in
          <:subtitle>
            <%= if @current_scope do %>
              confirm it's you
            <% else %>
              or <.link navigate={~p"/users/register"} class="bracketed">register</.link>
            <% end %>
          </:subtitle>
        </.header>

        <.form
          for={@form}
          id="login_form"
          action={~p"/users/log-in"}
          phx-submit="submit"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={@form[:username]}
            type="text"
            label="username"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.input
            field={@form[:password]}
            type="password"
            label="password"
            autocomplete="current-password"
            spellcheck="false"
            required
          />
          <.input type="checkbox" field={@form[:remember_me]} label="remember me" />
          <.button variant="primary" phx-disable-with="logging in...">log in</.button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    username =
      Phoenix.Flash.get(socket.assigns.flash, :username) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:username)])

    form = to_form(%{"username" => username}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
