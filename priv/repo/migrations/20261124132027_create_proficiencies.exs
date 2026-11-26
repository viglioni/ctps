defmodule Ctps.Repo.Migrations.CreateProficiencies do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE ctps.proficiency_kind AS ENUM ('skill','combat_category','weapon','armor','tool')"

    create table(:proficiencies) do
      add :kind, :"ctps.proficiency_kind", null: false
      add :name, :string, null: false
      add :description, :text

      add :equipment_id,
          references(:equipments, on_delete: :restrict),
          null: true

      timestamps(type: :utc_datetime)
    end

    execute """
    ALTER TABLE ctps.proficiencies
    ADD CONSTRAINT proficiencies_equipment_id_required
    CHECK (
      (kind IN ('weapon','armor','tool') AND equipment_id IS NOT NULL)
      OR
      (kind NOT IN ('weapon','armor','tool'))
    )
    """
  end

  def down do
    drop table(:proficiencies)
    execute "DROP TYPE ctps.proficiency_kind"
  end
end
