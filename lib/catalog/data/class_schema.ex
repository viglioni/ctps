defmodule Catalog.Data.ClassSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  @schema_prefix "ctps"
  @primary_key {:slug, :string, autogenerate: false}

  typed_schema "classes" do
    field :name, :string
    field :hit_die, :integer
    field :main_attrs, {:array, Ecto.Enum}, values: Ctps.attributes()
    field :main_attrs_bin_op, Ecto.Enum, values: [:or, :and]
    field :saving_throw, {:array, Ecto.Enum}, values: Ctps.attributes()
    field :skill_number, :integer
    field :init_gold_option, :integer

    timestamps(type: :utc_datetime)
  end

  @required ~w(slug name hit_die main_attrs main_attrs_bin_op saving_throw skill_number init_gold_option)a

  @doc false
  def changeset(class, attrs) do
    class
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
