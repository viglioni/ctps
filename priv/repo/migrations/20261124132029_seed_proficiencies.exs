defmodule Ctps.Repo.Migrations.SeedProficiencies do
  use Ecto.Migration

  @skills [
    "Acrobacia",
    "Arcanismo",
    "Atletismo",
    "Atuação",
    "Enganação",
    "Furtividade",
    "História",
    "Intimidação",
    "Intuição",
    "Investigação",
    "Lidar com Animais",
    "Medicina",
    "Natureza",
    "Percepção",
    "Persuasão",
    "Prestidigitação",
    "Religião",
    "Sobrevivência"
  ]

  @combat_categories [
    "Armas Simples",
    "Armas Marciais",
    "Armaduras Leves",
    "Armaduras Médias",
    "Armaduras Pesadas",
    "Escudos"
  ]

  def up do
    execute insert_sql("skill", @skills)
    execute insert_sql("combat_category", @combat_categories)

    execute """
    INSERT INTO ctps.proficiencies (kind, name, equipment_id, inserted_at, updated_at)
    SELECT
      kind::text::ctps.proficiency_kind,
      name,
      id,
      now(), now()
    FROM ctps.equipments
    """
  end

  def down do
    execute "TRUNCATE ctps.proficiencies RESTART IDENTITY CASCADE"
  end

  defp insert_sql(kind, names) do
    values =
      names
      |> Enum.map(fn n -> "('#{kind}', '#{escape(n)}', now(), now())" end)
      |> Enum.join(", ")

    "INSERT INTO ctps.proficiencies (kind, name, inserted_at, updated_at) VALUES #{values}"
  end

  defp escape(str), do: String.replace(str, "'", "''")
end
