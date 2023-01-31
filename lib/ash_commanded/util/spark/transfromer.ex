defmodule AshCommanded.Util.Spark.Transfromer do
  @moduledoc """
  Helper functions for working with Ash Resource Dsl
  """

  alias Ash.Resource.Info
  alias Spark.Dsl.Transformer

  def add_attribute_if_not_exists(dsl_state, type, name, opts) do
    if Info.attribute(dsl_state, name) do
      dsl_state
    else
      {:ok, attribute} =
        Transformer.build_entity(Ash.Resource.Dsl, [:attributes], type, [{:name, name} | opts])

      dsl_state
      |> Transformer.add_entity([:attributes], attribute)
    end
  end
end
