defmodule Shared.Repo.Behaviours.Selector do
  @moduledoc """
  Behaviour + default impl for read-only queries.

      defmodule MyApp.Foos do
        use Shared.Repo.Behaviours.Selector, schema: MyApp.Foo
      end

      MyApp.Foos.list()
      MyApp.Foos.list(order_by: :title)
      MyApp.Foos.list(order_by: [desc: :inserted_at])
      MyApp.Foos.get_one(id)
      MyApp.Foos.get_by(slug: "x")
  """

  alias Shared.ErrorM
  alias Shared.Monad, as: M

  @typedoc """
  Options accepted by `list/1`.

    * `:order_by` — anything `Ecto.Query.order_by/2` accepts
      (atom, list of atoms, or `[asc: :field, desc: :other]`).
  """
  @type list_opts :: [order_by: atom() | [atom()] | keyword()]

  @callback list() :: M.either([struct()], ErrorM.t())
  @callback list(list_opts()) :: M.either([struct()], ErrorM.t())
  @callback get_one(term()) :: M.either(struct(), ErrorM.t())
  @callback get_by(keyword() | map()) :: M.either(struct(), ErrorM.t())

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour Shared.Repo.Behaviours.Selector
      require Ecto.Query

      @impl true
      def list(opts \\ []) do
        unquote(schema)
        |> maybe_order_by(Keyword.get(opts, :order_by))
        |> Ctps.Repo.all()
        |> M.return()
      end

      @impl true
      def get_one(id),
        do: Ctps.Repo.get(unquote(schema), id) |> M.lift_nilable(ErrorM.not_found(id, &get_one/1))

      @impl true
      def get_by(clauses),
        do:
          Ctps.Repo.get_by(unquote(schema), clauses)
          |> M.lift_nilable(ErrorM.not_found(clauses, &get_by/1))

      defp maybe_order_by(query, nil), do: query
      defp maybe_order_by(query, order), do: Ecto.Query.order_by(query, ^order)

      defoverridable Shared.Repo.Behaviours.Selector
    end
  end
end
