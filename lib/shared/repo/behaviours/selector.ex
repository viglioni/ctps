defmodule Shared.Repo.Behaviours.Selector do
  @moduledoc """
  Behaviour + default impl pra queries read-only.

      defmodule MyApp.Foos do
        use Shared.Repo.Behaviours.Selector, schema: MyApp.Foo
      end

      MyApp.Foos.list()
      MyApp.Foos.get_one(id)
      MyApp.Foos.get_by(slug: "x")
  """

  @callback list() :: [struct()]
  @callback get_one(term()) :: struct() | nil
  @callback get_by(keyword() | map()) :: struct() | nil

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour Shared.Repo.Behaviours.Selector

      @impl true
      def list, do: Ctps.Repo.all(unquote(schema))

      @impl true
      def get_one(id), do: Ctps.Repo.get(unquote(schema), id)

      @impl true
      def get_by(clauses), do: Ctps.Repo.get_by(unquote(schema), clauses)

      defoverridable Shared.Repo.Behaviours.Selector
    end
  end
end
