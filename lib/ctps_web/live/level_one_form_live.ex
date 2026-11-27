defmodule CtpsWeb.LevelOneFormLive do
  alias Shared.ErrorM
  alias Shared.Data
  alias Catalog.Data.BackgroundSchema
  alias CtpsWeb.Components.SimpleTable
  alias Catalog.Data.Backgrounds
  alias Catalog.Data.ClassSchema
  alias Catalog.Data.Classes

  alias Ctps.Data.LevelOneFormSchema
  use CtpsWeb, :live_view
  use Shared.Monad

  alias CtpsWeb.LevelOneFormComponents.BackgroundSelector

  @attr_costs [
    {"Valor", "Custo"},
    {8, 0},
    {9, 1},
    {10, 2},
    {11, 3},
    {12, 4},
    {13, 5},
    {14, 7},
    {15, 9}
  ]

  @spec mount(any(), any(), socket()) :: M.ok(socket())
  def mount(_params, _session, socket) do
    form = %LevelOneFormSchema{} |> LevelOneFormSchema.changeset(%{}) |> to_form()

    classes_options =
      Classes.list()
      |> fmap_compose(fn %ClassSchema{name: name, slug: slug} -> {name, slug} end)

    backgrounds = Backgrounds.list(order_by: :title)

    socket
    |> assign(errorM: [])
    |> assign(form: form)
    |> assignM(classes_options: classes_options)
    |> assignM(backgrounds: backgrounds)
    |> assign(background_selected: nil)
    |> assign(attrs_coins: 27)
    |> assign(attr_costs: @attr_costs)
    |> return()
  end

  def handle_event("validate", %{"level_one_form_schema" => params}, socket) do
    form =
      %LevelOneFormSchema{}
      |> LevelOneFormSchema.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_info({:bg_selected, slug}, socket) do
    class_slug = socket.assigns.form[:class_slug].value

    form =
      %LevelOneFormSchema{}
      |> LevelOneFormSchema.changeset(%{background_slug: slug, class_slug: class_slug})
      |> to_form()

    bg_selectedM =
      socket.assigns.backgrounds
      |> Enum.find(&(&1.slug == slug))
      |> Data.fetch_proficiencies()

    socket
    |> assign(form: form)
    |> assignM(background_selected: bg_selectedM)
    |> return(:noreply)
  end

  @spec render(socket()) :: rendered()
  def render(assigns) do
    ~H"""
    <div :if={@errorM != []}>
      <.list :for={%ErrorM{} = error <- @errorM}>
        <:item title="⚠️ Erros!! Mande print para a Laura ⚠️">
          <p>{error.msg} <span>{error.kind}</span></p>
        </:item>
      </.list>
      <.hline />
    </div>

    <.form for={@form} phx-change="validate">
      <.input
        field={@form[:class_slug]}
        type="select"
        label="Classe"
        options={@classes_options}
        prompt="Escolha uma classe"
      />

      <.live_component
        module={BackgroundSelector}
        id="background-selector"
        form={@form}
        backgrounds={@backgrounds}
      />

      <p :if={@background_selected}>{@background_selected.description}</p>

      <.hline />

      <h2>Atributos base</h2>

      <p>Escolha (compre) seus attributos totalizando {@attrs_coins} pontos de custo:</p>

      <SimpleTable.simple_table
        data={@attr_costs}
        id="attr_costs"
        transpose
        class="border-collapse mx-auto my-4 w-auto text-xs [&_td]:border [&_td]:border-base-content/40 [&_td]:px-1.5 [&_td]:py-0.5 [&_td]:text-center [&_td]:min-w-[1.5rem] [&_td:first-child]:tracking-wider [&_td:first-child]:uppercase [&_td:first-child]:px-2"
      />

      <.skills background_selected={@background_selected} />
    </.form>
    """
  end

  attr :background_selected, BackgroundSchema, default: nil

  defp skills(assigns) do
    ~H"""
    <div :if={@background_selected}>
      <h2>Perícias</h2>
      <p>Por ser {@background_selected.title}, você ganha proficiência nas seguintes perícias:</p>
    </div>
    """
  end
end
