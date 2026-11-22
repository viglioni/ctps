defmodule Ctps.Repo.Migrations.BootstrapRpgFallback do
  @moduledoc """
  Fallback pra ambientes sem laura-db: cria o mínimo de `rpg.*` que o CTPS
  referencia via FK (site_players, campaigns, equipamentos) e o enum
  `rpg.creature_size`. Shape mínimo — campos opcionais ficam fora.

  Em ambiente com laura-db presente (dev normal), tudo é noop via
  `IF NOT EXISTS` / `DO` blocks.
  """

  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS rpg"

    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'rpg' AND t.typname = 'creature_size'
      ) THEN
        CREATE TYPE rpg.creature_size AS ENUM (
          'Miúdo', 'Pequeno', 'Médio', 'Grande', 'Enorme', 'Imenso'
        );
      END IF;
    END$$
    """

    execute """
    CREATE TABLE IF NOT EXISTS rpg.site_players (
      id         serial PRIMARY KEY,
      name       text NOT NULL,
      slug       text NOT NULL,
      is_npc     boolean NOT NULL DEFAULT false,
      created_at timestamptz NOT NULL DEFAULT now()
    )
    """

    execute "CREATE UNIQUE INDEX IF NOT EXISTS site_players_name_key ON rpg.site_players (name)"
    execute "CREATE UNIQUE INDEX IF NOT EXISTS site_players_slug_key ON rpg.site_players (slug)"

    execute """
    CREATE TABLE IF NOT EXISTS rpg.campaigns (
      id               serial PRIMARY KEY,
      slug             text NOT NULL,
      name             text NOT NULL,
      master           text NOT NULL,
      start_date       date,
      end_date         date,
      level_up_config  jsonb NOT NULL DEFAULT '{}',
      cover_image_path text,
      initial_pts      integer NOT NULL DEFAULT 27 CHECK (initial_pts >= 0),
      extra_talent     boolean NOT NULL DEFAULT false
    )
    """

    execute "CREATE UNIQUE INDEX IF NOT EXISTS site_campaigns_slug_key ON rpg.campaigns (slug)"

    execute "ALTER TABLE rpg.campaigns ADD COLUMN IF NOT EXISTS initial_pts integer NOT NULL DEFAULT 27"
    execute "ALTER TABLE rpg.campaigns ADD COLUMN IF NOT EXISTS extra_talent boolean NOT NULL DEFAULT false"

    execute """
    CREATE TABLE IF NOT EXISTS rpg.equipamentos (
      id        serial PRIMARY KEY,
      slug      text NOT NULL,
      nome      text NOT NULL,
      categoria text NOT NULL
    )
    """

    execute "CREATE UNIQUE INDEX IF NOT EXISTS equipamentos_slug_key ON rpg.equipamentos (slug)"
  end

  def down do
    :ok
  end
end
