defmodule Ctps.Repo.Migrations.CreateCtps do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS ctps"

    execute """
    CREATE TYPE ctps.alignment AS ENUM (
      'leal_bom', 'neutro_bom', 'caotico_bom',
      'leal_neutro', 'neutro', 'caotico_neutro',
      'leal_mau', 'neutro_mau', 'caotico_mau'
    )
    """

    execute "CREATE TYPE ctps.gender AS ENUM ('m', 'f', 'nb')"

    execute """
    CREATE TYPE ctps.proficiency_kind AS ENUM (
      'salvaguarda', 'pericia', 'armadura', 'arma', 'ferramenta', 'idioma'
    )
    """

    execute """
    CREATE TYPE ctps.proficiency_level AS ENUM (
      'non_proficient', 'half', 'proficient', 'expert'
    )
    """

    execute """
    CREATE TYPE ctps.proficiency_source AS ENUM (
      'classe', 'subclasse', 'antecedente', 'especie', 'talento', 'item_magico'
    )
    """

    create table(:ctps) do
      add :slug, :text, null: false
      add :name, :text, null: false
      add :player_id, references(:site_players, prefix: "rpg", on_delete: :restrict), null: false
      add :campaign_id, references(:campaigns, prefix: "rpg", on_delete: :restrict, type: :integer), null: false
      add :alignment, :"ctps.alignment"
      add :gender, :"ctps.gender"
      add :size, :"rpg.creature_size"

      add :base_str, :smallint, null: false
      add :base_dex, :smallint, null: false
      add :base_con, :smallint, null: false
      add :base_int, :smallint, null: false
      add :base_wis, :smallint, null: false
      add :base_cha, :smallint, null: false

      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create unique_index(:ctps, [:slug])
    create index(:ctps, [:player_id])
    create index(:ctps, [:campaign_id])

    for ab <- ~w(str dex con int wis cha) do
      create constraint(:ctps, "ctps_base_#{ab}_range",
               check: "base_#{ab} BETWEEN 1 AND 30")
    end

    create table(:proficiencies) do
      add :kind, :"ctps.proficiency_kind", null: false
      add :slug, :text, null: false
      add :name, :text, null: false
      add :external_id, references(:equipamentos, prefix: "rpg", on_delete: :restrict, type: :integer)
    end

    create unique_index(:proficiencies, [:kind, :slug])
    create index(:proficiencies, [:external_id])

    create table(:character_proficiencies) do
      add :character_id, references(:ctps, on_delete: :delete_all), null: false
      add :proficiency_id, references(:proficiencies, on_delete: :restrict), null: false
      add :level, :"ctps.proficiency_level", null: false
      add :source, :"ctps.proficiency_source", null: false
      add :source_ref, :map, null: false, default: %{}

      timestamps(inserted_at: :created_at, type: :utc_datetime, updated_at: false)
    end

    create index(:character_proficiencies, [:character_id])
    create unique_index(:character_proficiencies, [:character_id, :proficiency_id, :source],
             name: :character_proficiencies_char_prof_source_key)

    seed()
  end

  def down do
    drop table(:character_proficiencies)
    drop table(:proficiencies)
    drop table(:ctps)
    execute "DROP TYPE ctps.proficiency_source"
    execute "DROP TYPE ctps.proficiency_level"
    execute "DROP TYPE ctps.proficiency_kind"
    execute "DROP TYPE ctps.gender"
    execute "DROP TYPE ctps.alignment"
  end

  defp seed do
    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name) VALUES
      ('salvaguarda', 'for', 'Força'),
      ('salvaguarda', 'des', 'Destreza'),
      ('salvaguarda', 'con', 'Constituição'),
      ('salvaguarda', 'int', 'Inteligência'),
      ('salvaguarda', 'sab', 'Sabedoria'),
      ('salvaguarda', 'car', 'Carisma')
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name) VALUES
      ('pericia', 'acrobacia',         'Acrobacia'),
      ('pericia', 'arcanismo',         'Arcanismo'),
      ('pericia', 'atletismo',         'Atletismo'),
      ('pericia', 'atuacao',           'Atuação'),
      ('pericia', 'enganacao',         'Enganação'),
      ('pericia', 'furtividade',       'Furtividade'),
      ('pericia', 'historia',          'História'),
      ('pericia', 'intimidacao',       'Intimidação'),
      ('pericia', 'intuicao',          'Intuição'),
      ('pericia', 'investigacao',      'Investigação'),
      ('pericia', 'lidar_com_animais', 'Lidar com Animais'),
      ('pericia', 'medicina',          'Medicina'),
      ('pericia', 'natureza',          'Natureza'),
      ('pericia', 'percepcao',         'Percepção'),
      ('pericia', 'persuasao',         'Persuasão'),
      ('pericia', 'prestidigitacao',   'Prestidigitação'),
      ('pericia', 'religiao',          'Religião'),
      ('pericia', 'sobrevivencia',     'Sobrevivência')
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name) VALUES
      ('armadura', 'leves',    'Armaduras Leves'),
      ('armadura', 'medias',   'Armaduras Médias'),
      ('armadura', 'pesadas',  'Armaduras Pesadas'),
      ('armadura', 'escudos',  'Escudos')
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name) VALUES
      ('arma', 'simples',  'Armas Simples'),
      ('arma', 'marciais', 'Armas Marciais')
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name, external_id)
    SELECT 'arma', slug, nome, id
      FROM rpg.equipamentos
     WHERE categoria IN (
       'Armas Simples Corpo a Corpo',
       'Armas Simples à Distância',
       'Armas Marciais Corpo a Corpo',
       'Armas Marciais à Distância'
     )
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name, external_id)
    SELECT 'armadura', slug, nome, id
      FROM rpg.equipamentos
     WHERE categoria IN (
       'Armaduras Leves',
       'Armaduras Médias',
       'Armaduras Pesadas',
       'Escudo'
     )
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, slug, name, external_id)
    SELECT 'ferramenta', slug, nome, id
      FROM rpg.equipamentos
     WHERE categoria IN (
       'Ferramentas de Artesão',
       'Kits e Outras Ferramentas',
       'Instrumentos Musicais'
     )
    """
  end
end
