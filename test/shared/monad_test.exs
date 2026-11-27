defmodule Shared.MonadTest do
  use ExUnit.Case, async: true

  alias Shared.ErrorM
  alias Shared.Monad
  import Shared.Monad

  doctest Shared.Monad, except: [left: 1, left: 3, lift_nilable: 2, bind: 2, tryM: 2]

  describe "is_monad/1 guard" do
    test "matches {:ok, _}", do: assert(is_monad({:ok, 1}))
    test "matches {:error, _}", do: assert(is_monad({:error, :boom}))
    test "matches :error atom", do: assert(is_monad(:error))
    test "matches lists", do: assert(is_monad([1, 2, 3]))
    test "matches empty list", do: assert(is_monad([]))
    test "matches %ErrorM{}", do: assert(is_monad(ErrorM.new(:unknown, "msg")))

    test "rejects nil", do: refute(is_monad(nil))
    test "rejects bare atoms", do: refute(is_monad(:other))
    test "rejects maps", do: refute(is_monad(%{a: 1}))
    test "rejects 3-tuples", do: refute(is_monad({:ok, 1, 2}))
    test "rejects integers", do: refute(is_monad(42))
    test "rejects other structs", do: refute(is_monad(~D[2026-01-01]))
    test "rejects {:foo, 1}", do: refute(is_monad({:foo, 1}))

    test "usable as a function head guard" do
      defmodule UsesGuard do
        import Shared.Monad
        def is?(v) when is_monad(v), do: true
        def is?(_), do: false
      end

      assert UsesGuard.is?({:ok, 1})
      assert UsesGuard.is?(:error)
      refute UsesGuard.is?(nil)
    end
  end

  describe "use Shared.Monad" do
    test "imports helpers and aliases module as M" do
      defmodule UsesMonad do
        use Shared.Monad
        def wrap(x), do: M.return(x)
        def is_m?(x) when is_monad(x), do: true
        def is_m?(_), do: false
      end

      assert UsesMonad.wrap(99) == {:ok, 99}
      assert UsesMonad.is_m?({:ok, 1})
      refute UsesMonad.is_m?(123)
    end
  end

  describe "left/1-3" do
    test "defaults kind to :unknown for plain values" do
      assert %ErrorM{kind: :unknown, msg: "boom", context: nil} = left("boom")
    end

    test "stringifies non-binary values via inspect" do
      assert %ErrorM{msg: ":missing"} = left(:missing)
      assert %ErrorM{msg: "[1, 2, 3]"} = left([1, 2, 3])
    end

    test "respects explicit kind" do
      assert %ErrorM{kind: :not_found} = left("x", :not_found)
    end

    test "carries context" do
      assert %ErrorM{context: %{id: 7}} = left("x", :invalid, %{id: 7})
    end

    test "wraps exceptions with :exception kind by default" do
      e = %RuntimeError{message: "oops"}

      assert %ErrorM{kind: :exception, msg: "oops"} = left(e)
    end

    test "respects explicit kind for exceptions" do
      e = %RuntimeError{message: "oops"}

      assert %ErrorM{kind: :invalid} = left(e, :invalid)
    end

    test "merges exception into context when context is a map" do
      e = %RuntimeError{message: "oops"}

      assert %ErrorM{context: ctx} = left(e, :exception, %{params: 1})
      assert ctx.params == 1
      assert ctx.exception == e
    end

    test "falls back to the exception as context when none provided" do
      e = %RuntimeError{message: "oops"}
      assert %ErrorM{context: ^e} = left(e)
    end
  end

  describe "right/1" do
    test "wraps anything in {:ok, _}" do
      assert right(1) == {:ok, 1}
      assert right(nil) == {:ok, nil}
      assert right([1, 2]) == {:ok, [1, 2]}
    end
  end

  describe "lift_nilable/2" do
    test "nil becomes a left with the given message" do
      assert %ErrorM{kind: :unknown, msg: "missing"} = lift_nilable(nil, "missing")
    end

    test "any other value becomes {:ok, value}" do
      assert lift_nilable(1, "missing") == {:ok, 1}
      assert lift_nilable(false, "missing") == {:ok, false}
      assert lift_nilable("x", "missing") == {:ok, "x"}
    end
  end

  describe "return/1-2 and lift/1" do
    test "return/1 wraps in {:ok, _}" do
      assert return(1) == {:ok, 1}
    end

    test "return/2 uses the given tag" do
      assert return(:sock, :noreply) == {:noreply, :sock}
      assert return(%{id: 1}, :reply) == {:reply, %{id: 1}}
    end

    test "lift/1 is an alias for return/1" do
      assert lift(1) == return(1)
    end
  end

  describe "fmap/2" do
    test "maps element-wise over lists" do
      assert fmap([1, 2, 3], &(&1 * 10)) == [10, 20, 30]
      assert fmap([], &(&1 * 10)) == []
    end

    test "maps the value inside {:ok, _}" do
      assert fmap({:ok, 2}, &(&1 + 1)) == {:ok, 3}
    end

    test "short-circuits on :error" do
      assert fmap(:error, fn _ -> raise "should not run" end) == :error
    end

    test "short-circuits on {:error, _}" do
      assert fmap({:error, :boom}, fn _ -> raise "should not run" end) == {:error, :boom}
    end

    test "short-circuits on %ErrorM{}" do
      err = ErrorM.new(:not_found, "missing")
      assert fmap(err, fn _ -> raise "should not run" end) == err
    end

    test "functor law: fmap identity == identity" do
      id = & &1
      assert fmap({:ok, 1}, id) == {:ok, 1}
      assert fmap([1, 2, 3], id) == [1, 2, 3]
      assert fmap(:error, id) == :error
    end

    test "functor law: fmap (f . g) == fmap f . fmap g" do
      f = &(&1 + 1)
      g = &(&1 * 2)
      composed = fn x -> f.(g.(x)) end

      assert fmap({:ok, 3}, composed) == fmap(fmap({:ok, 3}, g), f)
      assert fmap([1, 2, 3], composed) == fmap(fmap([1, 2, 3], g), f)
    end
  end

  describe "fmap_compose/2" do
    test "reaches into {:ok, [a]}" do
      assert fmap_compose({:ok, [1, 2, 3]}, &(&1 * 10)) == {:ok, [10, 20, 30]}
    end

    test "reaches into [ {:ok, a}, ... ]" do
      assert fmap_compose([{:ok, 1}, {:ok, 2}], &(&1 * 10)) == [{:ok, 10}, {:ok, 20}]
    end

    test "reaches into [[a]]" do
      assert fmap_compose([[1, 2], [3, 4]], &(&1 * 10)) == [[10, 20], [30, 40]]
    end

    test "reaches into {:ok, {:ok, a}}" do
      assert fmap_compose({:ok, {:ok, 1}}, &(&1 + 1)) == {:ok, {:ok, 2}}
    end

    test "outer error short-circuits" do
      assert fmap_compose(:error, &(&1 * 10)) == :error
      assert fmap_compose({:error, :boom}, &(&1 * 10)) == {:error, :boom}
    end

    test "inner error short-circuits but outer is traversed" do
      assert fmap_compose({:ok, :error}, &(&1 * 10)) == {:ok, :error}
      assert fmap_compose([:error, {:ok, 1}], &(&1 * 10)) == [:error, {:ok, 10}]
    end
  end

  describe "bind/2" do
    test "threads the value through on {:ok, _}" do
      assert bind({:ok, 1}, &right(&1 + 1)) == {:ok, 2}
    end

    test "short-circuits on {:error, _}" do
      assert bind({:error, :boom}, fn _ -> raise "should not run" end) == {:error, :boom}
    end

    test "short-circuits on :error" do
      assert bind(:error, fn _ -> raise "should not run" end) == :error
    end

    test "short-circuits on %ErrorM{}" do
      err = ErrorM.new(:not_found, "missing")
      assert bind(err, fn _ -> raise "should not run" end) == err
    end

    test "re-wraps plain values returned by func via return/1" do
      assert bind({:ok, 1}, &(&1 + 1)) == {:ok, 2}
    end

    test "captures raised exceptions as left" do
      result = bind({:ok, 1}, fn _ -> raise "boom" end)
      assert %ErrorM{kind: :exception, msg: "boom"} = result
    end

    test "monad law: left identity — return(x) >>= f == f.(x)" do
      f = fn x -> {:ok, x + 1} end
      assert bind(return(5), f) == f.(5)
    end

    test "monad law: right identity — m >>= return == m" do
      assert bind({:ok, 7}, &return/1) == {:ok, 7}
      assert bind({:error, :x}, &return/1) == {:error, :x}
    end

    test "monad law: associativity" do
      f = fn x -> {:ok, x + 1} end
      g = fn x -> {:ok, x * 2} end

      left = bind(bind({:ok, 3}, f), g)
      right = bind({:ok, 3}, fn x -> bind(f.(x), g) end)

      assert left == right
    end
  end

  describe "tryM/2" do
    test "lifts and applies on success" do
      assert tryM(1, &(&1 + 1)) == {:ok, 2}
    end

    test "captures raised exceptions as left" do
      result = tryM(1, fn _ -> raise "boom" end)
      assert %ErrorM{kind: :exception, msg: "boom"} = result
    end

    test "equivalent to return |> bind" do
      f = fn x -> {:ok, x * 3} end
      assert tryM(4, f) == (4 |> return() |> bind(f))
    end
  end

  describe "unlift!/1" do
    test "unwraps {:ok, value}" do
      assert unlift!({:ok, 42}) == 42
    end

    test "crashes on {:error, _}" do
      assert_raise FunctionClauseError, fn -> unlift!({:error, :boom}) end
    end

    test "crashes on :error" do
      assert_raise FunctionClauseError, fn -> unlift!(:error) end
    end

    test "crashes on %ErrorM{}" do
      assert_raise FunctionClauseError, fn ->
        unlift!(ErrorM.new(:not_found, "missing"))
      end
    end
  end

  describe "integration — the moduledoc pipeline" do
    test "happy path threads through fmap + bind" do
      result =
        "42"
        |> Monad.return()
        |> Monad.fmap(&String.to_integer/1)
        |> Monad.bind(fn n ->
          if n > 0, do: Monad.right(n), else: Monad.left("non-positive")
        end)

      assert result == {:ok, 42}
    end

    test "sad path short-circuits with ErrorM" do
      result =
        "0"
        |> Monad.return()
        |> Monad.fmap(&String.to_integer/1)
        |> Monad.bind(fn n ->
          if n > 0, do: Monad.right(n), else: Monad.left("non-positive")
        end)

      assert %ErrorM{kind: :unknown, msg: "non-positive"} = result
    end
  end
end
