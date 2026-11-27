defmodule Ctps.MixProject do
  use Mix.Project

  def project do
    [
      app: :ctps,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ctps.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.3"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:typed_ecto_schema, "~> 0.4"},
      {:typed_struct, "~> 0.3"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:ex_unit, :mix]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.migrate", "assets.setup", "assets.build"],
      "ecto.migrate": ["ecto.migrate --prefix ctps"],
      "ecto.migrations": ["ecto.migrations --prefix ctps"],
      "ecto.rollback": ["ecto.rollback --prefix ctps"],
      "ecto.drop": &drop_forbidden/1,
      "drop-ctps": &drop_schema_ctps/1,
      "drop-catalog": &drop_schema_catalog/1,
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind ctps", "esbuild ctps"],
      "assets.deploy": [
        "tailwind ctps --minify",
        "esbuild ctps --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end

  defp drop_forbidden(_args) do
    Mix.raise(
      "mix ecto.drop está bloqueado — ele dropparia o laura_db inteiro. Use mix drop-ctps ou mix drop-catalog."
    )
  end

  defp drop_schema_ctps(_args), do: drop_schema("ctps")
  defp drop_schema_catalog(_args), do: drop_schema("catalog")

  defp drop_schema(name) do
    {out, status} =
      System.cmd(
        "psql",
        ["-h", "localhost", "-U", "laura", "-d", "laura_db", "-c",
         ~s(DROP SCHEMA IF EXISTS "#{name}" CASCADE)],
        stderr_to_stdout: true
      )

    if status == 0 do
      Mix.shell().info("[ok] schema #{name} dropped")
    else
      Mix.raise("falha ao dropar schema #{name}:\n#{out}")
    end
  end
end
