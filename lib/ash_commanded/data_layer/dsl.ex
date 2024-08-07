defmodule AshCommanded.DataLayer.Dsl do
  @moduledoc """
  Dsl for the Commanded DataLayer
  """
  defmacro __using__(_opts) do
    quote do
      @projection %Spark.Dsl.Entity{
        name: :projection,
        describe: "Connects a different resoure as a projections",
        target: AshCommanded.DataLayer.Dsl.Projection,
        schema: [
          model: [
            type: :module,
            required: true,
            doc: """
            The Resource which should be connected
            """
          ],
          on: [
            type: {:list, :atom}
          ]
        ]
      }

      @commanded %Spark.Dsl.Section{
        name: :commanded,
        schema: [
          application: [
            type: :module,
            doc: "The Commanded Application to dispatch to",
            required: true
          ]
        ],
        entities: [
          @projection
        ]
      }

      use Spark.Dsl.Extension,
        sections: [@commanded],
        transformers: [
          AshCommanded.DataLayer.Transformer,
          AshCommanded.DataLayer.Transformer.Projection
        ]
    end
  end
end
