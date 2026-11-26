defmodule Catalog.Data.Equipments do
  alias Shared.Repo.Behaviours
  alias Catalog.Data.EquipmentSchema

  use Behaviours.Mutator, schema: EquipmentSchema
  use Behaviours.Selector, schema: EquipmentSchema
end
