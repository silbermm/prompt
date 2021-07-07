defmodule Prompt.Table do
  @moduledoc false

  alias __MODULE__

  @type input :: list(list())

  @type t :: %Table{
          data: input(),
          column_count: number(),
          row_count: number(),
          columns_length: map(),
          error: nil | :invalid
        }

  defstruct data: [[]], column_count: 0, row_count: 0, columns_length: %{}, error: nil

  @doc ""
  @spec new(input()) :: t()
  def new(data) do
    max_column_length_map = columns_length(data)
    column_index = max_column_length_map |> Map.keys() |> List.last()

    %Table{
      data: data,
      row_count: Enum.count(data),
      column_count: column_index + 1,
      columns_length: max_column_length_map
    }
  end

  @doc ""
  @spec row(t(), list()) :: String.t()
  def row(%Table{} = table, row) do
    row_str =
      for {column, idx} <- Enum.with_index(row) do
        column_string = column_str(column, Map.get(table.columns_length, idx))
        "| #{column_string} "
      end

    "#{row_str}|\n"
  end

  @doc ""
  @spec row_delimiter(t()) :: String.t()
  def row_delimiter(%Table{} = table) do
    row =
      for column_number <- 0..(table.column_count - 1) do
        # should get us the length of the largest cell in this column
        length = Map.get(table.columns_length, column_number)
        r = row_str(length)
        "+-#{r}-"
      end

    "#{row}+\n"
  end

  defp row_str(total_length) do
    Enum.map(1..total_length, fn _ ->
      "-"
    end)
  end

  defp column_str(word, column_length) do
    String.pad_trailing(word, column_length)
  end

  defp columns_length(matrix),
    do: Enum.reduce(matrix, %{}, &largest_column(Enum.with_index(&1), &2))

  defp largest_column(row, per_column_map) do
    Enum.reduce(row, per_column_map, fn {column, idx}, acc ->
      length = String.length(column)
      {_, updated} = Map.get_and_update(acc, idx, &update_map(&1, column))
      updated
    end)
  end

  defp update_map(nil, column), do: {nil, String.length(column)}

  defp update_map(curr, column) do
    column_count = String.length(column)

    if column_count > curr do
      {curr, column_count}
    else
      {curr, curr}
    end
  end
end
