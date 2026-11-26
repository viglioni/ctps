defmodule Shared.ErrorM do
  @moduledoc """
  Default shape for the left side of `Shared.Monad.either/1-2`.

  Fields:
  - `kind` — short atomic tag for pattern matching
  - `msg` — human-readable message
  - `context` — auxiliary info (params, caller…)
  """
  use TypedStruct

  @type kind :: :not_found | :invalid | :unauthorized | :conflict | :unknown | :exception | :left

  typedstruct do
    field :kind, kind(), enforce: true
    field :msg, String.t(), enforce: true
    field :context, any()
  end

  @spec new(kind(), String.t(), any()) :: t()
  def new(kind, msg, context \\ %{}) do
    %__MODULE__{kind: kind, msg: msg, context: context}
  end

  @spec not_found(any(), (... -> any())) :: t()
  def not_found(params, caller),
    do: new(:not_found, "Not found", %{params: params, caller: caller})

  @spec from_exception(Exception.t(), kind(), map() | nil) :: t()
  def from_exception(e, kind \\ :exception, context) when is_exception(e) do
    ctx = if context, do: Map.put(context, :exception, e), else: e
    new(kind, Exception.message(e), ctx)
  end
end
