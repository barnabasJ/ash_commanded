defmodule AshCommanded.Util.String do
  @moduledoc """
  Extra utility functions for working with Strings
  """
  def camelcase(string) do
    string
    |> String.split("_")
    |> Enum.map_join("", &String.capitalize/1)
  end
end
