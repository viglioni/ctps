defmodule Shared.Repo.Behaviours.Selector do
  @moduledoc """
  Behaviour + default impl for read-only queries.

      defmodule MyApp.Foos do
        use Shared.Repo.Behaviours.Selector, schema: MyApp.Foo
      end

      MyApp.Foos.list()
      MyApp.Foos.get_one(id)
      MyApp.Foos.get_by(slug: "x")
  """

  alias Shared.ErrorM
  alias Shared.Monad, as: M

  @callback list() :: M.either([struct()], ErrorM.t())
  @callback get_one(term()) :: M.either(struct(), ErrorM.t())
  @callback get_by(keyword() | map()) :: M.either(struct(), ErrorM.t())

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour Shared.Repo.Behaviours.Selector

      @impl true
      def list, do: Ctps.Repo.all(unquote(schema)) |> M.return()

      @impl true
      def get_one(id),
        do: Ctps.Repo.get(unquote(schema), id) |> M.lift_nilable(ErrorM.not_found(id, &get_one/1))

      @impl true
      def get_by(clauses),
        do:
          Ctps.Repo.get_by(unquote(schema), clauses)
          |> M.lift_nilable(ErrorM.not_found(clauses, &get_by/1))

      defoverridable Shared.Repo.Behaviours.Selector
    end
  end
end
