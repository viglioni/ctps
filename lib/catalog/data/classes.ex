defmodule Catalog.Data.Classes do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.ClassSchema

  use Behaviours.Mutator, schema: ClassSchema
  use Behaviours.Selector, schema: ClassSchema
end
