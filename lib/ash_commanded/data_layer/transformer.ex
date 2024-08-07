defmodule AshCommanded.DataLayer.Transformer do
  @moduledoc """
  Adds the configured policies to the resource
  """
  use Spark.Dsl.Transformer

  alias Ash.Resource.Info
  alias AshCommanded.DataLayer.Transformer.Util, as: TU
  alias AshCommanded.Util.Spark.Transfromer, as: T

  def transform(%{persist: %{module: module}} = dsl_state) do
    actions = Info.actions(dsl_state)
    attributes = Info.attributes(dsl_state)

    commands =
      module
      |> create_commands(actions, attributes)

    events =
      module
      |> create_events(actions, attributes)

    commands
    |> Enum.zip(events)
    |> create_command_handlers()

    create_router(module, commands)

    {:ok,
     T.add_attribute_if_not_exists(dsl_state, :attribute, :deleted_at,
       type: :utc_datetime,
       public?: true
     )}
  end

  defp create_router(module, commands) do
    defmodule Module.concat(module, Router) do
      use Commanded.Commands.Router

      identify(module, by: :id)

      Enum.map(commands, fn command ->
        dispatch(command, to: Module.concat(command, Handler), aggregate: module)
      end)
    end
    |> elem(1)
  end

  defp create_commands(module, actions, attributes) do
    Enum.map(actions, &create_command(module, &1, attributes))
  end

  def create_command(module, action, attributes) do
    defmodule TU.create_command_module_name(module, action) do
      @derive Jason.Encoder
      defstruct attributes |> Enum.map(fn attribute -> attribute.name end)

      use ExConstructor
    end
    |> elem(1)
  end

  defp create_command_handlers(command_event_pairs) do
    command_event_pairs
    |> Enum.map(&create_command_handler/1)
  end

  def create_command_handler({command, event}) do
    defmodule Module.concat(command, Handler) do
      @behaviour Commanded.Commands.Handler

      @event event

      @impl true
      def handle(aggregate, command_to_handle) do
        struct(@event, Map.from_struct(Map.merge(aggregate, command_to_handle)))
      end
    end
    |> elem(1)
  end

  defp create_events(module, actions, attributes) do
    Enum.map(actions, &create_event(module, &1, attributes))
  end

  def create_event(module, action, attributes) do
    defmodule TU.create_event_module_name(module, action.name) do
      @derive Jason.Encoder
      defstruct attributes |> Enum.map(fn attribute -> attribute.name end)

      use ExConstructor
    end
    |> elem(1)
  end

  def after?(Ash.Resource.Transformers.DefaultAccept), do: true

  def after?(_), do: false
end
