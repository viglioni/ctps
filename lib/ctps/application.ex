defmodule Ctps.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Ctps.Release.migrate()

    children = [
      CtpsWeb.Telemetry,
      Ctps.Repo,
      {DNSCluster, query: Application.get_env(:ctps, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ctps.PubSub},
      # Start a worker by calling: Ctps.Worker.start_link(arg)
      # {Ctps.Worker, arg},
      # Start to serve requests, typically the last entry
      CtpsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ctps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CtpsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
