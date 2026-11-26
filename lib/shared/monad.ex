defmodule Shared.Monad do
  ## Generic elixir monad
  @type ok(t) :: {:ok, t}

  ## Classic types
  @type maybe(t) :: {:ok, t} | :error
  @type either(t, e) :: {:ok, t} | {:error, e}

  ## Applying functorable types
  @type functor(t, e) :: either(t, e)
  @type functor(t) :: maybe(t) | list(t)

  ## The type to endofunctor'em all
  @type m(a, e) :: functor(a, e)
  @type m(a) :: functor(a) | functor(a, any())

  ## Guard: is the value one of the shapes covered by m/1?
  defguard is_monad(value)
           when (is_tuple(value) and tuple_size(value) == 2 and
                   (elem(value, 0) == :ok or elem(value, 0) == :error)) or
                  value == :error or
                  is_list(value)

  defmacro __using__(_opts) do
    quote do
      import Shared.Monad
      alias Shared.Monad, as: M
    end
  end

  ## Either
  @spec left(e) :: {:error, e} when e: var
  def left(something), do: {:error, something}
  @spec right(t) :: ok(t) when t: var
  def right(something), do: {:ok, something}

  @spec lift_nilable(e, a) :: either(a, e) when e: var, a: var
  def lift_nilable(nil, error), do: left(error)
  def lift_nilable(something, _error), do: right(something)

  ## Generic typeclass
  @spec return(t) :: ok(t) when t: var
  def return(something), do: {:ok, something}

  @spec return(t, m) :: {m, t} when t: var, m: var
  def return(something, monad), do: {monad, something}

  @spec lift(t) :: ok(t) when t: var
  def lift(something), do: {:ok, something}

  ## Functor
  @spec fmap(functor(a), (a -> b)) :: functor(b) when a: var, b: var
  def fmap(functor, function) when is_list(functor), do: Enum.map(functor, function)
  def fmap({:ok, something}, function), do: something |> function.() |> return()
  def fmap(:error, _fn), do: :error
  def fmap({:error, err}, _fn), do: left(err)

  ## Monad
  @spec bind(m(a), (a -> b)) :: m(b) when a: var, b: var
  def bind(monad, func) do
    case monad do
      {:ok, content} -> content |> func.() |> return()
      monad -> monad
    end
  rescue
    e -> left(e)
  end

  @spec tryM(a, (a -> b)) :: m(b) when a: var, b: var
  def tryM(something, func) do
    something |> return() |> bind(&func.(&1))
  end

  @spec unlift!(m(a)) :: a when a: var
  def unlift!({:ok, something}), do: something
end
