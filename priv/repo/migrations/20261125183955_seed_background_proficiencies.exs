defmodule Ctps.Repo.Migrations.SeedBackgroundProficiencies do
  use Ecto.Migration

  @skills_by_bg [
    {"acolyte", ["Intuição", "Religião"]},
    {"wayfarer", ["Furtividade", "Intuição"]},
    {"artisan", ["Investigação", "Persuasão"]},
    {"entertainer", ["Acrobacia", "Atuação"]},
    {"charlatan", ["Enganação", "Prestidigitação"]},
    {"criminal", ["Furtividade", "Prestidigitação"]},
    {"hermit", ["Medicina", "Religião"]},
    {"scribe", ["Investigação", "Percepção"]},
    {"farmer", ["Lidar com Animais", "Natureza"]},
    {"guard", ["Atletismo", "Percepção"]},
    {"guide", ["Furtividade", "Sobrevivência"]},
    {"sailor", ["Acrobacia", "Percepção"]},
    {"merchant", ["Lidar com Animais", "Persuasão"]},
    {"noble", ["História", "Persuasão"]},
    {"sage", ["Arcanismo", "História"]},
    {"soldier", ["Atletismo", "Intimidação"]}
  ]

  # Apenas ferramentas FIXAS (os bgs com "Escolha um tipo de..." ficam de fora;
  # entram depois numa tabela de choices separada).
  @tools_by_bg [
    {"acolyte", "Suprimentos de Calígrafo"},
    {"wayfarer", "Ferramentas de Ladrão"},
    {"charlatan", "Kit de Falsificação"},
    {"criminal", "Ferramentas de Ladrão"},
    {"hermit", "Kit de Herbalismo"},
    {"scribe", "Suprimentos de Calígrafo"},
    {"farmer", "Ferramentas de Carpinteiro"},
    {"guide", "Ferramentas de Cartógrafo"},
    {"sailor", "Ferramentas de Navegador"},
    {"merchant", "Ferramentas de Navegador"},
    {"sage", "Suprimentos de Calígrafo"}
  ]

  def up do
    # 1. "Suprimentos de Calígrafo" faltava em ctps.equipments (categoria 'Suprimentos' ficou de fora do seed anterior).
    execute """
    INSERT INTO ctps.equipments (name, kind, sub_kind, inserted_at, updated_at)
    VALUES ('Suprimentos de Calígrafo', 'tool', 'Ferramentas de Artesão', now(), now())
    """

    execute """
    INSERT INTO ctps.proficiencies (kind, name, equipment_id, inserted_at, updated_at)
    SELECT 'tool', name, id, now(), now()
    FROM ctps.equipments
    WHERE name = 'Suprimentos de Calígrafo' AND kind = 'tool'
    """

    # 2. Seedar background_proficiencies (skills + tools fixas).
    for {bg_slug, skill_names} <- @skills_by_bg,
        name <- skill_names do
      insert_pair(bg_slug, "skill", name)
    end

    for {bg_slug, tool_name} <- @tools_by_bg do
      insert_pair(bg_slug, "tool", tool_name)
    end
  end

  def down do
    execute "TRUNCATE ctps.background_proficiencies"

    execute """
    DELETE FROM ctps.proficiencies
    WHERE kind = 'tool' AND name = 'Suprimentos de Calígrafo'
    """

    execute """
    DELETE FROM ctps.equipments
    WHERE name = 'Suprimentos de Calígrafo' AND kind = 'tool'
    """
  end

  defp insert_pair(bg_slug, kind, prof_name) do
    execute """
    INSERT INTO ctps.background_proficiencies (background_slug, proficiency_id)
    SELECT '#{bg_slug}', p.id
    FROM ctps.proficiencies p
    WHERE p.kind = '#{kind}' AND p.name = '#{escape(prof_name)}'
    """
  end

  defp escape(str), do: String.replace(str, "'", "''")
end
