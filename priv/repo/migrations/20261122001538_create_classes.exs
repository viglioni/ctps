defmodule Ctps.Repo.Migrations.CreateClasses do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE ctps.bin_op AS ENUM ('or', 'and')"

    create table(:classes) do
      add :name, :string, null: false
      add :hit_die, :integer, null: false
      add :main_attrs, {:array, :string}, null: false
      add :main_attrs_bin_op, :"ctps.bin_op", null: false, default: "and"
      add :saving_throw, {:array, :string}, null: false
      add :skill_number, :integer, null: false
      add :init_gold_option, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:classes, [:name])
  end

  def down do
    drop table(:classes)
    execute "DROP TYPE ctps.bin_op"
  end
end
