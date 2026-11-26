defmodule Ctps.Repo.Migrations.CreateEquipments do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE ctps.equipment_kind AS ENUM ('weapon','armor','tool')"

    create table(:equipments) do
      add :name, :string, null: false
      add :kind, :"ctps.equipment_kind", null: false
      add :sub_kind, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end

  def down do
    drop table(:equipments)
    execute "DROP TYPE ctps.equipment_kind"
  end
end
