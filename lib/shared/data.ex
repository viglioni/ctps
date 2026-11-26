defmodule Shared.Data do
  alias Shared.Monad, as: M
  require M

  @spec fetch_proficiencies(a | M.m(a)) :: M.m(a) when a: var
  def fetch_proficiencies(schemaM) when M.is_monad(schemaM),
    do: M.bind(schemaM, &Ctps.Repo.preload(&1, :proficiencies))

  def fetch_proficiencies(schema), do: M.tryM(schema, &Ctps.Repo.preload(&1, :proficiencies))
end
