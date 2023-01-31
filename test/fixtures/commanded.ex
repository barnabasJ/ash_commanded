defmodule CommandedTest do
  @moduledoc false

  defmodule A do
    @moduledoc false
    defmodule Projection do
      @moduledoc false
      use Ash.Resource, data_layer: Ash.DataLayer.Ets

      attributes do
        uuid_primary_key(:id, generated?: false)
        attribute(:title, :string)
      end

      actions do
        defaults([:create, :update, :destroy, :read])
      end
    end

    defmodule Aggregate do
      @moduledoc false
      use Ash.Resource, data_layer: AshCommanded.DataLayer.Commanded

      commanded do
        application(CommandedTest.C.Application)
        api(CommandedTest.A.Api)

        projection do
          model(Projection)
          on([:create, :update, :destroy])
        end
      end

      attributes do
        uuid_primary_key(:id)
        attribute(:title, :string)
      end

      actions do
        defaults([:create, :update, :destroy])
      end

      def apply(aggregate, event) do
        ExConstructor.populate_struct(aggregate, event)
      end
    end

    defmodule Registry do
      @moduledoc false
      use Ash.Registry,
        extensions: [Ash.Registry.ResourceValidations]

      entries do
        entry(Aggregate)
        entry(Projection)
      end
    end

    defmodule Api do
      @moduledoc false
      use Ash.Api

      resources do
        registry(Registry)
      end
    end
  end

  defmodule C do
    @moduledoc false
    defmodule Application do
      @moduledoc false
      alias Commanded.EventStore.Adapters.InMemory
      alias Commanded.Serialization.JsonSerializer

      use AshCommanded.DataLayer.Application,
        api: CommandedTest.A.Api,
        otp_app: :commanded,
        event_store: [
          adapter: InMemory,
          serializer: JsonSerializer
        ]
    end
  end
end
