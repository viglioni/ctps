defmodule Ctps.Repo.Migrations.CreateBackgroundProficiencies do
  use Ecto.Migration

  def up do
    create table(:background_proficiencies, primary_key: false) do
      add :background_slug,
          references(:backgrounds,
            column: :slug,
            type: :string,
            on_delete: :delete_all
          ),
          primary_key: true,
          null: false

      add :proficiency_id,
          references(:proficiencies, on_delete: :restrict),
          primary_key: true,
          null: false
    end
  end

  def down do
    drop table(:background_proficiencies)
  end
end
