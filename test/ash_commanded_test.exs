defmodule AshCommanded.DataLayer.CommandedTest do
  use ExUnit.Case, async: true

  require Ash.Query

  alias CommandedTest.{A, C}

  setup do
    app_pid = start_supervised!(C.Application)
    projector_pid = start_supervised!(A.Aggregate.Supervisor)

    [app_pid: app_pid, projector_pid: projector_pid]
  end

  test "a resource can be created" do
    agg =
      A.Aggregate
      |> Ash.Changeset.for_create(:create, %{title: "Title"})
      |> Ash.create!()

    assert agg.id != nil
    assert agg.title == "Title"

    projection =
      A.Projection
      |> Ash.Query.filter(id == ^agg.id)
      |> Ash.read_one!()

    assert projection.id == agg.id
    assert projection.title == agg.title
  end

  test "a resource can be updated" do
    agg =
      A.Aggregate
      |> Ash.Changeset.for_create(:create, %{title: "Title"})
      |> Ash.create!()

    assert agg.id != nil
    assert agg.title == "Title"

    projection =
      A.Projection
      |> Ash.Query.filter(id == ^agg.id)
      |> Ash.read_one!()

    assert projection.id == agg.id
    assert projection.title == agg.title

    updated_agg =
      agg
      |> Ash.Changeset.for_update(:update, %{title: "New Title"})
      |> Ash.update!()

    assert updated_agg.id == agg.id
    assert updated_agg.title == "New Title"

    projection =
      A.Projection
      |> Ash.Query.filter(id == ^agg.id)
      |> Ash.read_one!()

    assert projection.id == updated_agg.id
    assert projection.title == updated_agg.title
  end

  test "a resource can destroyed" do
    agg =
      A.Aggregate
      |> Ash.Changeset.for_create(:create, %{title: "Title"})
      |> Ash.create!()

    assert agg.id != nil
    assert agg.title == "Title"

    projection =
      A.Projection
      |> Ash.Query.filter(id == ^agg.id)
      |> Ash.read_one!()

    assert projection.id == agg.id
    assert projection.title == agg.title

    agg
    |> Ash.Changeset.for_destroy(:destroy)
    |> Ash.destroy!()

    projection =
      A.Projection
      |> Ash.Query.filter(id == ^agg.id)
      |> Ash.read_one!()

    assert projection == nil
  end
end
