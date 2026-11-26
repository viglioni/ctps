defmodule CtpsWeb.Components.SimpleTable do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :data, :list, required: true, doc: "list of tuples; each tuple is a row, each element a cell"
  attr :class, :string, default: nil
  attr :transpose, :boolean, default: false, doc: "if true, rows become columns"

  def simple_table(assigns) do
    assigns = assign(assigns, :data, maybe_transpose(assigns.data, assigns.transpose))

    ~H"""
    <table id={@id} class={@class || "table table-zebra"}>
      <tbody>
        <tr :for={row <- @data}>
          <td :for={cell <- row}>{cell}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp maybe_transpose(data, true) do
    data
    |> Enum.map(&to_cells/1)
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  defp maybe_transpose(data, _false), do: Enum.map(data, &to_cells/1)

  defp to_cells(row) when is_tuple(row), do: Tuple.to_list(row)
  defp to_cells(row) when is_list(row), do: row
end
