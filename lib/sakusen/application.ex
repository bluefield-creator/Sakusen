defmodule Sakusen.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SakusenWeb.Telemetry,
      Sakusen.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:sakusen, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:sakusen, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Sakusen.PubSub},
      # Start a worker by calling: Sakusen.Worker.start_link(arg)
      # {Sakusen.Worker, arg},
      # Start to serve requests, typically the last entry
      SakusenWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sakusen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SakusenWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
