defmodule Ctps.Selector do
  @moduledoc """
  Behaviour + default impl pra queries read-only.

      defmodule MyApp.Foos do
        use Ctps.Selector, schema: MyApp.Foo
      end

      MyApp.Foos.list()
      MyApp.Foos.get_one(id)
      MyApp.Foos.get_by(slug: "x")
  """
  alias Shared.Monad, as: M

  @callback list() :: [struct()]
  @callback get_one(term()) :: struct() | nil
  @callback get_by(keyword() | map()) :: struct() | nil

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour Ctps.Selector

      @impl true
      def list, do: Ctps.Repo.all(unquote(schema)) |> M.return()

      @impl true
      def get_one(id), do: Ctps.Repo.get(unquote(schema), id) |> M.lift_nilable(:not_found)

      @impl true
      def get_by(clauses),
        do: Ctps.Repo.get_by(unquote(schema), clauses) |> M.lift_nilable(:not_found)

      defoverridable Ctps.Selector
    end
  end
end
