defmodule AshCommanded.DataLayer.Info do
  @moduledoc """
  Introspection functions for the Audit Extension
  """
  alias Spark.Dsl.Extension

  def application(resource) do
    Extension.get_opt(resource, [:commanded], :application)
  end

  def api(resource) do
    Extension.get_opt(resource, [:commanded], :api)
  end

  def projections(resource) do
    Extension.get_entities(resource, [:commanded])
  end
end
