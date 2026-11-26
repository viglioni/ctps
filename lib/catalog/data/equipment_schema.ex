defmodule Catalog.Data.EquipmentSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  @schema_prefix "ctps"

  typed_schema "equipments" do
    field :name, :string
    field :kind, Ecto.Enum, values: [:weapon, :armor, :tool]
    field :sub_kind, :string

    timestamps(type: :utc_datetime)
  end

  @required ~w(name kind sub_kind)a

  @doc false
  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
