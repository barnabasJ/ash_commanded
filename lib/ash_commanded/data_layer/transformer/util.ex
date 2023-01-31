defmodule AshCommanded.DataLayer.Transformer.Util do
  @moduledoc """
  Utilities for creating the necessary Infrastructure for the
  Commanded DataLayer
  """

  alias AshCommanded.Util

  def create_command_module_name(module, action) do
    Module.concat(
      module,
      to_atom(
        get_action_name(action.name) <>
          get_resource_name(module)
      )
    )
  end

  def create_event_module_name(module, action) do
    Module.concat(
      module,
      to_atom(
        get_resource_name(module) <>
          get_action_name(action) <> "ed"
      )
    )
  end

  def create_projector_module_name(module, projection, action) do
    [
      module,
      to_atom(get_resource_name(module)),
      to_atom(get_resource_name(projection.model)),
      to_atom(get_action_name(action.name)),
      Projector
    ]
    |> Enum.reduce(fn x, acc -> Module.concat(acc, x) end)
  end

  def create_supervisor_module_name(module) do
    [
      module,
      Supervisor
    ]
    |> Enum.reduce(fn x, acc -> Module.concat(acc, x) end)
  end

  def get_action_name(name), do: Util.String.camelcase(Atom.to_string(name))

  defp get_resource_name(module),
    do:
      Module.split(module)
      |> Enum.reverse()
      |> hd()

  defp to_atom(string) do
    String.to_existing_atom(string)
  rescue
    _ -> String.to_atom(string)
  end
end
