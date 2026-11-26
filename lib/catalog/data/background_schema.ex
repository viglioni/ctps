defmodule Catalog.Data.BackgroundSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Catalog.Data.JoinBackgroundProficiencySchema
  alias Catalog.Data.ProficiencySchema

  @schema_prefix "ctps"
  @primary_key {:slug, :string, autogenerate: false}

  typed_schema "backgrounds" do
    field :title, :string
    field :description, :string
    field :attr_one, Ecto.Enum, values: Ctps.attributes()
    field :attr_two, Ecto.Enum, values: Ctps.attributes()
    field :attr_three, Ecto.Enum, values: Ctps.attributes()
    field :gold_option, :integer
    field :feat_slug, :string

    many_to_many :proficiencies, ProficiencySchema,
      join_through: JoinBackgroundProficiencySchema,
      join_keys: [background_slug: :slug, proficiency_id: :id]
  end

  @required ~w(slug title description attr_one attr_two attr_three gold_option feat_slug)a

  @doc false
  def changeset(background, attrs) do
    background
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
