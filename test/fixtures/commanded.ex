defmodule CommandedTest do
  @moduledoc false

  defmodule A do
    @moduledoc false
    defmodule Projection do
      @moduledoc false
      use Ash.Resource, data_layer: Ash.DataLayer.Ets, domain: CommandedTest.A.Domain

      attributes do
        uuid_primary_key(:id, generated?: false, public?: true, writable?: true)
        attribute(:title, :string, public?: true)
      end

      actions do
        default_accept(:*)
        defaults([:create, :update, :destroy, :read])
      end
    end

    defmodule Aggregate do
      @moduledoc false
      use Ash.Resource,
        data_layer: AshCommanded.DataLayer.Commanded,
        domain: CommandedTest.A.Domain

      commanded do
        application(CommandedTest.C.Application)

        projection do
          model(Projection)
          on([:create, :update, :destroy])
        end
      end

      attributes do
        uuid_primary_key(:id)
        attribute(:title, :string, public?: true)
      end

      actions do
        default_accept(:*)
        defaults([:create, :update, :destroy])
      end

      def apply(aggregate, event) do
        ExConstructor.populate_struct(aggregate, event)
      end
    end

    defmodule Domain do
      @moduledoc false
      use Ash.Domain

      resources do
        resource(CommandedTest.A.Aggregate)
        resource(CommandedTest.A.Projection)
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
        domain: CommandedTest.A.Domain,
        otp_app: :commanded,
        event_store: [
          adapter: InMemory,
          serializer: JsonSerializer
        ]
    end
  end
end
