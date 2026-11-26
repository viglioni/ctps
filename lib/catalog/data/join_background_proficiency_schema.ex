defmodule Catalog.Data.JoinBackgroundProficiencySchema do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Catalog.Data.BackgroundSchema
  alias Catalog.Data.ProficiencySchema

  @schema_prefix "ctps"
  @primary_key false

  typed_schema "background_proficiencies" do
    belongs_to :background, BackgroundSchema,
      foreign_key: :background_slug,
      references: :slug,
      type: :string,
      primary_key: true

    belongs_to :proficiency, ProficiencySchema, primary_key: true
  end

  @required ~w(background_slug proficiency_id)a

  @doc false
  def changeset(join, attrs) do
    join
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
