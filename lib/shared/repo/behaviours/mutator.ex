defmodule Shared.Repo.Behaviours.Mutator do
  @moduledoc """
  Behaviour + default impl pra create/update/delete.

  Requer que o schema exponha `changeset/2`.

      defmodule MyApp.Foos do
        use Shared.Repo.Behaviours.Selector, schema: MyApp.Foo
        use Shared.Repo.Behaviours.Mutator,  schema: MyApp.Foo
      end
  """

  @callback create(map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @callback update(struct(), map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @callback delete(struct()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @callback change(struct(), map()) :: Ecto.Changeset.t()

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)

    quote do
      @behaviour Shared.Repo.Behaviours.Mutator

      @impl true
      def create(attrs) do
        struct(unquote(schema))
        |> unquote(schema).changeset(attrs)
        |> Ctps.Repo.insert()
      end

      @impl true
      def update(record, attrs) do
        record
        |> unquote(schema).changeset(attrs)
        |> Ctps.Repo.update()
      end

      @impl true
      def delete(record), do: Ctps.Repo.delete(record)

      @impl true
      def change(record, attrs \\ %{}), do: unquote(schema).changeset(record, attrs)

      defoverridable Shared.Repo.Behaviours.Mutator
    end
  end
end
