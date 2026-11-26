defmodule Ctps.Repo.Migrations.SeedEquipments do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO ctps.equipments (name, kind, sub_kind, inserted_at, updated_at)
    SELECT
      nome,
      (CASE
        WHEN categoria LIKE 'Armas %' THEN 'weapon'
        WHEN categoria LIKE 'Armaduras %' OR categoria = 'Escudo' THEN 'armor'
        ELSE 'tool'
      END)::ctps.equipment_kind,
      categoria,
      now(), now()
    FROM rpg.equipamentos
    WHERE categoria LIKE 'Armas %'
       OR categoria LIKE 'Armaduras %'
       OR categoria = 'Escudo'
       OR categoria IN ('Ferramentas de Artesão', 'Kits e Outras Ferramentas', 'Instrumentos Musicais')
    """
  end

  def down do
    execute "TRUNCATE ctps.equipments RESTART IDENTITY CASCADE"
  end
end
