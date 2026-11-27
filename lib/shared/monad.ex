defmodule Shared.Monad do
  @moduledoc """
  Haskell-flavoured monad helpers on top of Elixir's `{:ok, _} | {:error, _}` idiom.

  Covers three shapes under the umbrella type `m/1`:

    * `either(a, e)` — `{:ok, a} | {:error, e} | ErrorM.t()`
    * `maybe(a)`    — `{:ok, a} | :error | nil`
    * `list(a)`     — plain Elixir lists

  Standard toolkit: `return/1`, `fmap/2`, `bind/2`. `left/1-3` builds an
  `ErrorM.t()` (the canonical left side), `right/1` wraps a value on the right.

  `use Shared.Monad` imports the module and aliases it as `M`, so call sites read
  `M.fmap(...)` / `M.bind(...)`.

  ## Example

      use Shared.Monad

      "42"
      |> M.return()
      |> M.fmap(&String.to_integer/1)
      |> M.bind(fn n -> if n > 0, do: M.right(n), else: M.left("non-positive") end)
      #=> {:ok, 42}
  """

  alias Shared.ErrorM

  @typedoc "Right side of `either`."
  @type ok(t) :: {:ok, t}

  @typedoc "Haskell-style `Maybe` using `:ok | :error | nil`."
  @type maybe(t) :: {:ok, t} | :error | nil

  @typedoc "Haskell-style `Either`, with `ErrorM.t()` as the canonical left."
  @type either(t, e) :: {:ok, t} | {:error, e} | ErrorM.t()

  @typedoc "Any functor shape with an explicit error channel."
  @type functor(t, e) :: either(t, e)

  @typedoc "Any functor shape without a dedicated error channel."
  @type functor(t) :: maybe(t) | list(t)

  @typedoc "Umbrella type covering every shape handled by this module."
  @type m(a, e) :: functor(a, e)
  @type m(a) :: functor(a) | functor(a, any())

  @doc """
  True when `value` matches any shape covered by `m/1`.

  Use it as a guard to accept polymorphic monadic values.

  ## Example

      def unwrap_or(v, default) when is_monad(v) do
        case v do
          {:ok, x} -> x
          _ -> default
        end
      end
  """
  defguard is_monad(value)
           when (is_tuple(value) and tuple_size(value) == 2 and
                   (elem(value, 0) == :ok or elem(value, 0) == :error)) or
                  value == :error or
                  is_list(value) or
                  is_struct(value, ErrorM)

  @doc """
  `use Shared.Monad` imports every helper and aliases the module as `M`.

  ## Example

      defmodule MyMod do
        use Shared.Monad

        def double(x), do: x |> M.return() |> M.fmap(&(&1 * 2))
      end
  """
  defmacro __using__(_opts) do
    quote do
      import Shared.Monad
      alias Shared.Monad, as: M
    end
  end

  @doc """
  Build the left side of an `either`.

  Returns an `ErrorM.t()`. If `e` is an exception, it is wrapped via
  `ErrorM.from_exception/3`; otherwise a fresh `ErrorM` with `kind` and a
  stringified message is built. `kind` defaults to `:exception` for exceptions
  and `:unknown` otherwise.

  ## Examples

      Shared.Monad.left("boom")
      #=> %Shared.ErrorM{kind: :unknown, msg: "boom", context: nil}

      Shared.Monad.left("missing", :not_found, %{id: 7})
      #=> %Shared.ErrorM{kind: :not_found, msg: "missing", context: %{id: 7}}

      Shared.Monad.left(%RuntimeError{message: "oops"})
      #=> %Shared.ErrorM{kind: :exception, msg: "oops", context: %{...}}
  """
  @spec left(any()) :: ErrorM.t()
  @spec left(any(), ErrorM.kind() | nil) :: ErrorM.t()
  @spec left(any(), ErrorM.kind() | nil, any()) :: ErrorM.t()
  def left(e, kind \\ nil, context \\ nil) do
    if is_exception(e) do
      ErrorM.from_exception(e, kind || :exception, context)
    else
      ErrorM.new(kind || :unknown, stringify(e), context)
    end
  end

  defp stringify(e) when is_binary(e), do: e
  defp stringify(e), do: inspect(e)

  @doc """
  Build the right side of an `either` — i.e. wrap a value in `{:ok, value}`.

  ## Example

      iex> Shared.Monad.right(42)
      {:ok, 42}
  """
  @spec right(t) :: ok(t) when t: var
  def right(something), do: {:ok, something}

  @doc """
  Promote a possibly-nil value into an `either`.

  `nil` becomes `left(error)`; anything else becomes `right(value)`.

  ## Examples

      Shared.Monad.lift_nilable(1, "missing")
      #=> {:ok, 1}

      Shared.Monad.lift_nilable(nil, "missing")
      #=> %Shared.ErrorM{kind: :unknown, msg: "missing", context: nil}
  """
  @spec lift_nilable(e, a) :: either(a, e) when e: var, a: var
  def lift_nilable(nil, error), do: left(error)
  def lift_nilable(something, _error), do: right(something)

  @doc """
  Monadic `return` — lifts a plain value into `{:ok, value}`.

  ## Example

      iex> Shared.Monad.return(42)
      {:ok, 42}
  """
  @spec return(t) :: ok(t) when t: var
  def return(something), do: {:ok, something}

  @doc """
  Two-arg variant useful for LiveView callbacks: wraps `something` as the
  payload of an arbitrary tag (e.g. `return(socket, :noreply)`).

  ## Example

      iex> Shared.Monad.return(:sock, :noreply)
      {:noreply, :sock}
  """
  @spec return(t, m) :: {m, t} when t: var, m: var
  def return(something, monad), do: {monad, something}

  @doc """
  Alias for `return/1`.

  ## Example

      iex> Shared.Monad.lift(42)
      {:ok, 42}
  """
  @spec lift(t) :: ok(t) when t: var
  def lift(something), do: {:ok, something}

  @doc """
  Functor `fmap` over any shape covered by `functor/1-2`.

  `{:ok, a}` maps to `{:ok, f.(a)}`; lists map element-wise; errors
  (`:error`, `{:error, _}`, `%ErrorM{}`) short-circuit.

  ## Examples

      iex> Shared.Monad.fmap({:ok, 2}, &(&1 * 10))
      {:ok, 20}

      iex> Shared.Monad.fmap([1, 2, 3], &(&1 * 10))
      [10, 20, 30]

      iex> Shared.Monad.fmap(:error, &(&1 * 10))
      :error

      iex> Shared.Monad.fmap({:error, :boom}, &(&1 * 10))
      {:error, :boom}
  """
  @spec fmap(functor(a), (a -> b)) :: functor(b) when a: var, b: var
  def fmap(functor, function) when is_list(functor), do: Enum.map(functor, function)
  def fmap({:ok, something}, function), do: something |> function.() |> return()
  def fmap(:error, _fn), do: :error
  def fmap({:error, _err} = e, _fn), do: e
  def fmap(%ErrorM{} = e, _fn), do: e

  @doc """
  `fmap` through two nested functor layers in one shot — Elixir's answer to
  `fmap . fmap` / `Data.Functor.Compose` from Haskell.

  Useful for things like `{:ok, [a]}` where `fmap/2` alone would only reach
  the list, not its elements.

  ## Examples

      iex> Shared.Monad.fmap_compose({:ok, [1, 2, 3]}, &(&1 * 10))
      {:ok, [10, 20, 30]}

      iex> Shared.Monad.fmap_compose([{:ok, 1}, {:ok, 2}], &(&1 * 10))
      [{:ok, 10}, {:ok, 20}]

      iex> Shared.Monad.fmap_compose(:error, &(&1 * 10))
      :error
  """
  @spec fmap_compose(functor(functor(a)), (a -> b)) :: functor(functor(b)) when a: var, b: var
  def fmap_compose(ffunctor, function) do
    fmap(
      ffunctor,
      fn inner_functor ->
        fmap(
          inner_functor,
          fn value -> function.(value) end
        )
      end
    )
  end

  @doc """
  Monadic `bind` (Haskell's `>>=`).

  On `{:ok, a}`, applies `func` and re-wraps with `return/1`. Any other shape
  short-circuits. Exceptions raised inside `func` are captured as `left(e)`.

  ## Examples

      Shared.Monad.bind({:ok, "42"}, &String.to_integer/1)
      #=> {:ok, 42}

      Shared.Monad.bind({:error, :boom}, &String.to_integer/1)
      #=> {:error, :boom}

      Shared.Monad.bind({:ok, "nope"}, &String.to_integer/1)
      #=> %Shared.ErrorM{kind: :exception, msg: "errors on to_integer...", context: %{...}}
  """
  @spec bind(m(a), (a -> b)) :: m(b) when a: var, b: var
  def bind(monad, func) do
    case monad do
      {:ok, content} -> content |> func.() |> return()
      monad -> monad
    end
  rescue
    e -> left(e)
  end

  @doc """
  Run a potentially raising function and capture the result monadically.

  Equivalent to `return(something) |> bind(func)`.

  ## Examples

      Shared.Monad.tryM("42", &String.to_integer/1)
      #=> {:ok, 42}

      Shared.Monad.tryM("nope", &String.to_integer/1)
      #=> %Shared.ErrorM{kind: :exception, msg: "errors on to_integer...", context: %{...}}
  """
  @spec tryM(a, (a -> b)) :: m(b) when a: var, b: var
  def tryM(something, func) do
    something |> return() |> bind(&func.(&1))
  end

  @doc """
  Unsafely unwrap `{:ok, value}`. Crashes on anything else.

  ## Example

      iex> Shared.Monad.unlift!({:ok, 42})
      42
  """
  @spec unlift!(m(a)) :: a when a: var
  def unlift!({:ok, something}), do: something
end
