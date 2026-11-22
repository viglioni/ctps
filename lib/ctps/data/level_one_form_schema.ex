defmodule Ctps.Data.LevelOneFormSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  typed_embedded_schema do
    field :class_id, :id
  end

  @required ~w(class_id)a

  def changeset(form, attrs) do
    form
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
