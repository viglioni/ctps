# Decisões de DB — CTPS

Documento-vivo das decisões de modelagem. Atualizar quando algo mudar.

## Infra

- **DB compartilhado**: `laura_db` localhost (mesmo do laura-db).
- **Dois schemas**:
  - `rpg.*` — catálogo D&D, **laura-db é dono do DDL**. CTPS consome e usa como fallback bootstrap em ambiente standalone.
  - `ctps.*` — tabelas próprias do app (ficha + proficiências).
- **Runner de migrations**: Ecto. Rodam no boot automaticamente via `Ctps.Release.migrate/0` (hook em `Application.start/2`). Também `bin/ctps eval "Ctps.Release.migrate()"` em prod.
- **Prefix default**: `migration_default_prefix: "ctps"` no `config/dev.exs` + `--prefix ctps` auto via alias em `mix.exs`.
- **`Ctps.Release.migrate/0`** cria schema `ctps` antes de rodar migrations (chicken-and-egg do `ctps.schema_migrations`).
- **Ordem**:
  1. `20261119190000_bootstrap_rpg_fallback` — cria `rpg.*` mínimo + enum `rpg.creature_size` se não existirem (`IF NOT EXISTS`). Noop em ambiente com laura-db.
  2. `20261119194657_create_ctps` — cria `ctps.*` + seed de 106 proficiências.

## Convenções

| | |
|---|---|
| **Nome de tabela/coluna/módulo** | inglês (`base_str`, `sheets`, `equipment_id`) |
| **Valor de enum (dado persistido)** | PT-BR (`leal_bom`, `salvaguarda`, `Miúdo`) |
| **Enum PG** | nome do tipo em EN, labels PT-BR |
| **Ecto schema** | usa `Ecto.Enum` com atoms (lowercase_snake no Elixir), keyword-list mapeando pra string PT-BR quando houver acento/espaço |
| **Primary key** | `bigserial id` como regra. Exceção: `rpg.subclasses` usa `slug text PK` (herdado do laura-db); `rpg.site_players` é `serial integer` (idem) |
| **FKs** | explícitas com `ON DELETE` definido conscientemente (`restrict` pra referência de catálogo, `cascade` pra ownership) |
| **Timestamps** | `inserted_at: :created_at` (compat com laura-db que usa `created_at`); `updated_at` só nas tabelas que mutam |

## Tabela `ctps.ctps` (ficha)

```sql
id            bigserial PK
slug          text NOT NULL UNIQUE
name          text NOT NULL
player_id     bigint NOT NULL REFERENCES rpg.site_players(id) ON DELETE RESTRICT
campaign_id   integer NOT NULL REFERENCES rpg.campaigns(id) ON DELETE RESTRICT
alignment     ctps.alignment    NULL
gender        ctps.gender       NULL
size          rpg.creature_size NULL
base_str      smallint NOT NULL CHECK (BETWEEN 1 AND 30)
base_dex      smallint NOT NULL CHECK (...)
base_con      smallint NOT NULL CHECK (...)
base_int      smallint NOT NULL CHECK (...)
base_wis      smallint NOT NULL CHECK (...)
base_cha      smallint NOT NULL CHECK (...)
created_at    timestamptz NOT NULL
updated_at    timestamptz NOT NULL
```

**Decisões:**
- Nome da tabela é `ctps` (dentro do schema `ctps`) — meta-joke, CTPS = **C**haracter **T**TRPG **P**lain **S**heet.
- `base_*` em EN, embora `for/des/con/int/sab/car` sejam os valores no enum de salvaguardas.
- Check 1–30 porque teto normal é 20 em criação, mas buffs temporários podem elevar até 30.
- `player_id` e `campaign_id` NOT NULL (ficha sempre pertence a jogador + campanha, alinhado com `rpg.characters`).
- `alignment`, `gender`, `size` nullable (rascunho de ficha pode começar sem definir).

## Tabela `ctps.proficiencies` (catálogo)

```sql
id           bigserial PK
kind         ctps.proficiency_kind NOT NULL
slug         text NOT NULL
name         text NOT NULL
external_id  integer REFERENCES rpg.equipamentos(id)  -- renomear pra equipment_id (pendente)
UNIQUE (kind, slug)
```

**Decisões:**
- **Decidimos ter catálogo** (reverter da "tabela desnecessária" inicial) porque `kind='arma', slug='espada-longa'` precisa de um lugar de verdade (seed com external_id → `rpg.equipamentos`).
- **external_id → equipamentos**: usado pra armas/armaduras/ferramentas específicas (não categorias). Nullable porque saves/perícias/categorias não têm.
- **Problema aberto**: nome `external_id` é genérico — polimorfismo implícito. Decidimos renomear pra `equipment_id` + CHECK constraint, mas isso conflita com as 6 rows de categoria (`simples`, `marciais`, `leves`, …) que têm `kind IN (arma, armadura)` mas sem `external_id`. **Decisão pendente**.

**Seed inicial (106 linhas):**
- 6 salvaguardas: `for, des, con, int, sab, car` (sem external_id)
- 18 perícias (sem external_id)
- 4 categorias de armadura: `leves, medias, pesadas, escudos`
- 2 categorias de arma: `simples, marciais`
- 17 armaduras específicas (`external_id → rpg.equipamentos`)
- 38 armas específicas (idem)
- 21 ferramentas (idem)

Categorias usam **slug plural** (`leves, marciais`) pra não colidir com slugs de itens em `rpg.equipamentos` (ex: `escudo` singular = item).

## Tabela `ctps.character_proficiencies` (join)

```sql
id              bigserial PK
character_id    bigint NOT NULL REFERENCES ctps.ctps(id) ON DELETE CASCADE
proficiency_id  bigint NOT NULL REFERENCES ctps.proficiencies(id) ON DELETE RESTRICT
level           ctps.proficiency_level NOT NULL
source          ctps.proficiency_source NOT NULL
source_ref      jsonb NOT NULL DEFAULT '{}'
UNIQUE (character_id, proficiency_id, source)
```

**Decisões:**
- **Unique por `(character_id, proficiency_id, source)`** permite múltiplas fontes do mesmo prof. Ex: "furtividade vem da classe + da espécie". Útil pra auditoria.
- **`level` enum** com 4 valores: `non_proficient, half, proficient, expert`.
  - `non_proficient`: sem ganho (ainda assim guardamos linha explícita se vier de uma fonte)
  - `half`: metade do PB (Bardo "Pau pra Toda Obra")
  - `proficient`: PB normal
  - `expert`: 2×PB (perícias com Especialização) OU "tem weapon mastery" (armas)
- **Semântica por kind**:
  - Salvaguarda: só `proficient`
  - Perícia: todos os 4
  - Arma: `proficient` normal, `expert` = mastery
  - Armadura: `proficient`
  - Ferramenta: `proficient` ou `expert`
  - Idioma: `proficient`
- **`source` enum**: `classe, subclasse, antecedente, especie, talento, item_magico`. Identifica onde veio.
- **`source_ref jsonb`**: detalhe da fonte (ex: `{"class_id": 1, "feature_slug": "pau-pra-toda-obra"}`, `{"feat_slug": "resiliente"}`).

## Tipos enum (`ctps.*`)

```sql
ctps.alignment            = leal_bom | neutro_bom | caotico_bom | leal_neutro | neutro |
                            caotico_neutro | leal_mau | neutro_mau | caotico_mau
ctps.gender               = m | f | nb
ctps.proficiency_kind     = salvaguarda | pericia | armadura | arma | ferramenta | idioma
ctps.proficiency_level    = non_proficient | half | proficient | expert
ctps.proficiency_source   = classe | subclasse | antecedente | especie | talento | item_magico
```

Reusados de `rpg.*`:
- `rpg.creature_size` = Miúdo | Pequeno | Médio | Grande | Enorme | Imenso

## Mudanças que fizemos em `rpg.*` (laura-db)

- **`rpg.campaigns`**: adicionadas colunas `initial_pts int DEFAULT 27 CHECK (>= 0)` e `extra_talent bool DEFAULT false`.
  - Migration: `laura-db/rpg/migrations/2026-11-19_campaigns_initial_pts_extra_talent.sql`
  - Já deployada no HS.

## Fórmulas mapeadas (D&D 5.5 PT-BR)

Salvaguarda = `d20 + mod_atributo + (PB se proficient)`

Perícia = `d20 + mod_atributo + bônus_proficiência`, onde bônus depende do level:
- none: 0
- half: `floor(PB/2)` (Pau pra Toda Obra do Bardo)
- proficient: PB
- expert: 2×PB (Especialização)

## Decisões pendentes / próximos passos

- [ ] **Renomear `ctps.proficiencies.external_id` → `equipment_id`** com FK explícita + resolver conflito das categorias (ver 3 opções abaixo).
- [ ] **Mover `proficiencies` de `ctps.*` pra `rpg.*`** — é vocabulário D&D, não app. Permite `rpg.classes` referenciar sem inverter direção de dependência (laura-db vs ctps).
- [ ] **Criar `rpg.class_proficiencies` (N:N)** entre classes e proficiências (hoje `rpg.classes.weapon_proficiency` é jsonb heterogêneo; `tool_proficiency` idem; `armor_training` é text[]).
- [ ] **Decidir categorias vs itens no catálogo** (hoje misturadas em `kind=arma`):
  - (a) Novo kind pras categorias: `arma_categoria`, `armadura_categoria`.
  - (b) Coluna `is_category boolean`.
  - (c) Tirar categorias do catálogo; viram coluna `category` em `class_proficiencies`.
- [ ] **Modelar regras de proficiência de arma** dinamicamente (ex: Ladino = marciais com Acuidade OR Leve + todas simples): tabela `rpg.class_weapon_rules(class_id, category, property_any[], property_all[])` com query que expande em runtime.
- [ ] **CHECK constraint**: `equipment_id NOT NULL` quando `kind IN (arma, armadura, ferramenta)` — depende de resolver as categorias primeiro.
- [ ] **Devolver `weapon_proficiency` + `tool_proficiency` ao Ecto schema `Rpg.Class`** (removidos por formato heterogêneo; recolocar se migrarmos pra tabela N:N dedicada).
- [ ] **Deploy do CTPS no HS** (Dockerfile + compose). Porta reservada: **61301**.

## Convenção Elixir / Ecto

- Behaviours: `Shared.Repo.Behaviours.Selector` (list/get_one/get_by) e `Shared.Repo.Behaviours.Mutator` (create/update/delete/change).
- Padrão por entity: schema module (ex: `Rpg.Spell`) + context module plural (ex: `Rpg.Spells`) que faz `use Shared.Repo.Behaviours.Selector`.
- Context `Ctps.Sheets` faz Selector+Mutator sobre `Ctps.Sheets.Sheet`.
- Enums do PG mapeados via `Ecto.Enum` (atom no Elixir ↔ string no DB).

---

## Snapshot das migrations (preservado antes de deletar)

### `20261119190000_bootstrap_rpg_fallback.exs`

```elixir
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
```

### `20261119194657_create_ctps.exs`

```elixir
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
```
