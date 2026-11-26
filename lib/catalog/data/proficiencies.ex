defmodule Catalog.Data.Proficiencies do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.ProficiencySchema

  use Behaviours.Mutator, schema: ProficiencySchema
  use Behaviours.Selector, schema: ProficiencySchema
end
