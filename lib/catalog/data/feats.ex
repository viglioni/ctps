defmodule Catalog.Data.Feats do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.FeatSchema

  use Behaviours.Mutator, schema: FeatSchema
  use Behaviours.Selector, schema: FeatSchema
end
