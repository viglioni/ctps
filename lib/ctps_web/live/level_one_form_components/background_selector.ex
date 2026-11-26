defmodule CtpsWeb.LevelOneFormComponents.BackgroundSelector do
  use CtpsWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :open?, false)}
  end

  @impl true
  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :open?, !socket.assigns.open?)}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open?, false)}
  end

  def handle_event("select", %{"slug" => slug}, socket) do
    send(self(), {:bg_selected, slug})
    {:noreply, assign(socket, :open?, false)}
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :backgrounds, :list, required: true
  attr :disabled, :boolean, default: false

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <div class="relative" phx-click-away="close" phx-target={@myself}>
        <span class="label mb-1">Antecedente</span>
        <button
          type="button"
          phx-click="toggle"
          phx-target={@myself}
          disabled={@disabled}
          class={["select w-full text-left", @disabled && "opacity-50 cursor-not-allowed"]}
        >
          {selected_bg_title(@form, @backgrounds)}
        </button>
        <input
          type="hidden"
          name={@form[:background_slug].name}
          value={@form[:background_slug].value || ""}
        />
        <%= if @open? and not @disabled do %>
          <ul
            role="listbox"
            class="absolute z-50 mt-1 w-full bg-base-100 rounded-box shadow-lg max-h-96 overflow-y-auto border border-base-300"
          >
            <%= for bg <- @backgrounds do %>
              <li
                role="option"
                phx-click="select"
                phx-value-slug={bg.slug}
                phx-target={@myself}
                class="grid grid-cols-[1fr_auto_auto_auto_auto] gap-x-4 px-4 py-2 hover:bg-base-200 cursor-pointer items-center"
              >
                <span>{bg.title}</span>
                <span class="text-xs opacity-60">({bg.feat_slug})</span>
                <span class="font-mono text-xs uppercase">{bg.attr_one}</span>
                <span class="font-mono text-xs uppercase">{bg.attr_two}</span>
                <span class="font-mono text-xs uppercase">{bg.attr_three}</span>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  defp selected_bg_title(form, backgrounds) do
    case form[:background_slug].value do
      slug when is_binary(slug) and slug != "" ->
        case Enum.find(backgrounds, &(&1.slug == slug)) do
          nil -> "Escolha um antecedente"
          bg -> bg.title
        end

      _ ->
        "Escolha um antecedente"
    end
  end
end
