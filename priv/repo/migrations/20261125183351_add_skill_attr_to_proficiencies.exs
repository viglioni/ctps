defmodule Ctps.Repo.Migrations.AddSkillAttrToProficiencies do
  use Ecto.Migration

  @skill_attrs %{
    "Acrobacia" => "dex",
    "Arcanismo" => "int",
    "Atletismo" => "for",
    "Atuação" => "cha",
    "Enganação" => "cha",
    "Furtividade" => "dex",
    "História" => "int",
    "Intimidação" => "cha",
    "Intuição" => "wis",
    "Investigação" => "int",
    "Lidar com Animais" => "wis",
    "Medicina" => "wis",
    "Natureza" => "int",
    "Percepção" => "wis",
    "Persuasão" => "cha",
    "Prestidigitação" => "dex",
    "Religião" => "int",
    "Sobrevivência" => "wis"
  }

  def up do
    alter table(:proficiencies) do
      add :skill_attr, :"ctps.attr"
    end

    for {name, attr} <- @skill_attrs do
      execute "UPDATE ctps.proficiencies SET skill_attr = '#{attr}' WHERE kind = 'skill' AND name = '#{escape(name)}'"
    end

    execute """
    ALTER TABLE ctps.proficiencies
    ADD CONSTRAINT proficiencies_skill_attr_required
    CHECK (
      (kind = 'skill' AND skill_attr IS NOT NULL)
      OR
      (kind != 'skill' AND skill_attr IS NULL)
    )
    """
  end

  def down do
    execute "ALTER TABLE ctps.proficiencies DROP CONSTRAINT proficiencies_skill_attr_required"

    alter table(:proficiencies) do
      remove :skill_attr
    end
  end

  defp escape(str), do: String.replace(str, "'", "''")
end
