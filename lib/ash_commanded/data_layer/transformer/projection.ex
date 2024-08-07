defmodule AshCommanded.DataLayer.Transformer.Projection do
  @moduledoc """
  Adds the necessary boilerplate to create a projection
  """

  use Spark.Dsl.Transformer

  alias AshCommanded.DataLayer.Info
  alias AshCommanded.DataLayer.Transformer.Util

  @impl true
  def transform(%{persist: %{module: module}} = dsl_state) do
    projections = Info.projections(dsl_state)
    application = Info.application(dsl_state)
    actions = Ash.Resource.Info.actions(dsl_state)

    module
    |> create_projectors(projections, actions, application)
    |> create_supervisor(module)

    {:ok, dsl_state}
  end

  def create_projectors(module, projections, actions, application) do
    projections
    |> Enum.flat_map(fn projection ->
      create_projectors(
        module,
        {projection, get_projection_actions(projection, actions)},
        application
      )
    end)
  end

  defp get_projection_actions(projection, actions) do
    actions
    |> Enum.filter(fn action ->
      projection.on
      |> Enum.any?(fn on ->
        action.name == on
      end)
    end)
  end

  def create_projectors(module, {projection, actions}, application) do
    actions
    |> Enum.map(fn action ->
      create_projector(module, projection, action, application)
    end)
  end

  def create_projector(module, projection, action, application) do
    module_name = Util.create_projector_module_name(module, projection, action)

    defmodule module_name do
      @module_name module_name
      @application application

      use Commanded.Event.Handler,
        name: Atom.to_string(@module_name),
        application: @application,
        consistency: :strong,
        start_from: :origin

      @match %{__struct__: Util.create_event_module_name(module, action.name)}

      @projection projection
      @action action

      case action.type do
        :create ->
          def handle(@match = event, _) do
            case @projection.model
                 |> Ash.Changeset.for_create(@action.name, Map.from_struct(event))
                 |> Ash.Changeset.force_change_attribute(:id, event.id)
                 |> Ash.create() do
              {:ok, _} ->
                :ok

              error ->
                error
            end
          end

        :update ->
          def handle(@match = event, _) do
            struct(@projection.model, %{id: event.id})
            |> Ash.Changeset.for_update(@action.name, Map.from_struct(event))
            |> Ash.update()

            :ok
          end

        :destroy ->
          def handle(@match = event, _) do
            struct(@projection.model, %{id: event.id})
            |> Ash.Changeset.for_destroy(@action.name)
            |> Ash.destroy()

            :ok
          end
      end
    end
    |> elem(1)
  end

  def create_supervisor(projectors, module) do
    defmodule Util.create_supervisor_module_name(module) do
      use Supervisor

      @projectors projectors

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def init(_arg) do
        Supervisor.init(@projectors, strategy: :one_for_one)
      end
    end
  end

  @impl true
  def after?(AshCommanded.DataLayer.Transformer), do: true
  def after?(_), do: false
end
