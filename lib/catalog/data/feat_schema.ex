defmodule Catalog.Data.FeatSchema do
  use TypedEctoSchema
  import Ecto.Changeset

  @schema_prefix "ctps"
  @primary_key {:slug, :string, autogenerate: false}

  typed_schema "feats" do
  end

  @required ~w(slug)a

  @doc false
  def changeset(feat, attrs) do
    feat
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
