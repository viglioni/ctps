defmodule Ctps.Release do
  @moduledoc """
  Tarefas de release — rodadas no boot (via Application.start/2) e também
  acessíveis via `bin/ctps eval "Ctps.Release.migrate()"` em produção.
  """

  @app :ctps
  @prefix "ctps"

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn r ->
          r.query!(~s(CREATE SCHEMA IF NOT EXISTS "#{@prefix}"))
          Ecto.Migrator.run(r, :up, all: true, prefix: @prefix)
        end)
    end
  end

  def rollback(repo, version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        repo,
        &Ecto.Migrator.run(&1, :down, to: version, prefix: @prefix)
      )
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
