defmodule Catalog.Data.ProficiencySchema do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Catalog.Data.EquipmentSchema

  @schema_prefix "ctps"

  typed_schema "proficiencies" do
    field :kind, Ecto.Enum, values: [:skill, :combat_category, :weapon, :armor, :tool]
    field :name, :string
    field :description, :string
    field :skill_attr, Ecto.Enum, values: Ctps.attributes()

    belongs_to :equipment, EquipmentSchema

    timestamps(type: :utc_datetime)
  end

  @required ~w(kind name)a
  @optional ~w(description equipment_id skill_attr)a
  @requires_equipment [:weapon, :armor, :tool]

  @doc false
  def changeset(proficiency, attrs) do
    proficiency
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_equipment_required()
    |> validate_skill_attr()
  end

  defp validate_equipment_required(changeset) do
    kind = get_field(changeset, :kind)
    equipment_id = get_field(changeset, :equipment_id)

    if kind in @requires_equipment and is_nil(equipment_id) do
      add_error(changeset, :equipment_id, "é obrigatório quando kind é weapon, armor ou tool")
    else
      changeset
    end
  end

  defp validate_skill_attr(changeset) do
    kind = get_field(changeset, :kind)
    skill_attr = get_field(changeset, :skill_attr)

    cond do
      kind == :skill and is_nil(skill_attr) ->
        add_error(changeset, :skill_attr, "é obrigatório quando kind é skill")

      kind != :skill and not is_nil(skill_attr) ->
        add_error(changeset, :skill_attr, "só é permitido quando kind é skill")

      true ->
        changeset
    end
  end
end
