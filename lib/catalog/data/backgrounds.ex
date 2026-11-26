defmodule Catalog.Data.Backgrounds do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.BackgroundSchema

  use Behaviours.Mutator, schema: BackgroundSchema
  use Behaviours.Selector, schema: BackgroundSchema
end
