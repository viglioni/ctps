defmodule CtpsWeb.NewSheetLive do
  alias Catalog.Data.ClassSchema
  alias Catalog.Data.Classes

  alias Ctps.Data.LevelOneFormSchema
  use CtpsWeb, :live_view
  use Shared.Monad

  @spec mount(any(), any(), socket()) :: M.ok(socket())
  def mount(_params, _session, socket) do
    form = %LevelOneFormSchema{} |> LevelOneFormSchema.changeset(%{}) |> to_form()

    classes_select = Classes.list() |> fmap(fn %ClassSchema{name: name, id: id} -> {name, id} end)

    socket
    |> assign(form: form)
    |> assign(classes_select: classes_select)
    |> return()
  end

  @spec render(socket()) :: rendered()
  def render(assigns) do
    ~H"""
    <.form for={@form}>
      <.input
        field={@form[:class_id]}
        type="select"
        label="Classe"
        options={@classes_select}
        prompt="Escolha uma classe"
      />
    </.form>
    """
  end
end
