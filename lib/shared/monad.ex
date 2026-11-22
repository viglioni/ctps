defmodule Shared.Monad do
  ## Generic elixir monad
  @type ok(t) :: {:ok, t}

  ## Classic types
  @type maybe(t) :: {:ok, t} | :error
  @type either(t, e) :: {:ok, t} | {:error, e}

  ## Applying functorable types
  @type functor(t, e) :: either(t, e)
  @type functor(t) :: maybe(t) | list(t)

  defmacro __using__(_opts) do
    quote do
      import Shared.Monad
      alias Shared.Monad, as: M
    end
  end

  ## Generic typeclass
  @spec return(t) :: ok(t) when t: var
  def return(something), do: {:ok, something}

  @spec lift(t) :: ok(t) when t: var
  def lift(something), do: {:ok, something}

  ## Either
  @spec left(e) :: {:error, e} when e: var
  def left(something), do: {:error, something}
  @spec right(t) :: ok(t) when t: var
  def right(something), do: {:ok, something}

  ## Functor
  @spec fmap(functor(a), (a -> b)) :: functor(b) when a: var, b: var
  def fmap(functor, function) when is_list(functor), do: Enum.map(functor, function)
  def fmap({:ok, something}, function), do: something |> function.() |> return()
  def fmap(:error, _fn), do: :error
  def fmap({:error, err}, _fn), do: left(err)
end
