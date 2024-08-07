defmodule AshCommanded.DataLayer.Commanded do
  @moduledoc """
  DataLayer that handles the connection between Commanded and Ash

  While we are still using the old system that writes directly to the db
  it probably makes not a lot of sense to have Resources use this as it
  would lead to inconsistencies between the aggregate and the projection
  in the db.
  """

  alias Commanded.Aggregates.Aggregate
  alias AshCommanded.DataLayer.Info
  alias AshCommanded.DataLayer.Transformer.Util

  @behaviour Ash.DataLayer

  # Most of these are set to false because commanded only handles the
  # write path. Reads are managed through projections.
  # I copied this from ash_csv and I think this can be simplified in
  # the future
  @impl true
  def can?(_, :read), do: false
  def can?(_, :create), do: true
  def can?(_, :update), do: true
  def can?(_, :upsert), do: true
  def can?(_, :destroy), do: true
  def can?(_, :sort), do: false
  def can?(_, :filter), do: false
  def can?(_, :limit), do: false
  def can?(_, :offset), do: false
  def can?(_, :boolean_filter), do: false
  def can?(_, :transact), do: true
  def can?(_, {:filter_expr, _}), do: false
  def can?(_, :nested_expressions), do: false
  def can?(_, {:sort, _}), do: false
  def can?(_, _), do: false

  @impl true
  def in_transaction?(_resource) do
    true
  end

  @impl true
  def create(resource, changeset) do
    app = Info.application(resource)

    command_module = Util.create_command_module_name(resource, changeset.action)

    command =
      struct(
        command_module,
        changeset.attributes
      )

    case app.dispatch(command, consistency: :strong) do
      :ok -> {:ok, Aggregate.aggregate_state(app, resource, command.id)}
      e -> {:error, e}
    end
  end

  @impl true
  def update(resource, changeset) do
    app = Info.application(resource)

    command_module = Util.create_command_module_name(resource, changeset.action)

    command =
      struct(
        command_module,
        Map.merge(
          Map.from_struct(changeset.data),
          changeset.attributes
        )
      )

    case app.dispatch(command, consistency: :strong) do
      :ok -> {:ok, Aggregate.aggregate_state(app, resource, command.id)}
      e -> {:error, e}
    end
  end

  @impl true
  def destroy(resource, changeset) do
    app = Info.application(resource)

    command_module = Util.create_command_module_name(resource, changeset.action)

    command =
      struct(
        command_module,
        Map.merge(
          Map.from_struct(changeset.data),
          changeset.attributes
        )
      )

    case app.dispatch(command, consistency: :strong) do
      :ok -> :ok
      e -> {:error, e}
    end
  end

  @impl true
  def resource_to_query(arg0, arg1) do
    dbg(["resource_to_query", arg0, arg1])
    :ok
  end

  use AshCommanded.DataLayer.Dsl
end
