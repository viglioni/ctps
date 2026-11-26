defmodule Ctps.Repo.Migrations.Backgrounds do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE ctps.attr AS ENUM ('for','dex','con','int','wis','cha')"

    create table(:feats, primary_key: false) do
      add :slug, :string, primary_key: true
    end

    create table(:backgrounds, primary_key: false) do
      add :slug, :string, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :attr_one, :"ctps.attr", null: false
      add :attr_two, :"ctps.attr", null: false
      add :attr_three, :"ctps.attr", null: false
      add :gold_option, :integer, null: false

      add :feat_slug,
          references(:feats, column: :slug, type: :string, on_delete: :restrict),
          null: false
    end
  end

  def down do
    drop table(:backgrounds)
    drop table(:feats)
    execute "DROP TYPE ctps.attr"
  end
end
