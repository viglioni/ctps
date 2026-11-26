defmodule Catalog.Data.JoinBackgroundProficiencies do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.JoinBackgroundProficiencySchema

  use Behaviours.Mutator, schema: JoinBackgroundProficiencySchema
  use Behaviours.Selector, schema: JoinBackgroundProficiencySchema
end
