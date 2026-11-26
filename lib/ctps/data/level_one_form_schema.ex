defmodule Ctps.Data.LevelOneFormSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  typed_embedded_schema do
    field :class_slug, :string
    field :background_slug, :string
    field :for, :integer
    field :dex, :integer
    field :con, :integer
    field :int, :integer
    field :wis, :integer
    field :cha, :integer
  end

  @required ~w(class_slug background_slug for dex con int wis cha)a

  def changeset(form, attrs) do
    form
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
