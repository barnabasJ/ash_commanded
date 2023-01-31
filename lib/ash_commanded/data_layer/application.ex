defmodule AshCommanded.DataLayer.Application do
  @moduledoc """
  Use for creating a Commanded Application that has the
  Rouer for Resources that use the Commanded DataLayer
  injected into it
  """

  defmacro __using__(opts) do
    quote do
      use Commanded.Application, unquote(opts)

      require Ash.Api.Info

      alias Ash.Api.Info

      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :resource, accumulate: true)

      unquote(opts[:api])
      |> List.wrap()
      |> Kernel.++(List.wrap(unquote(opts[:apis])))
      |> Enum.map(fn api -> Info.depend_on_resources(api) end)
      |> List.flatten()
      |> Stream.filter(fn
        resource ->
          Ash.DataLayer.data_layer(resource) == AshCommanded.DataLayer.Commanded
      end)
      |> Enum.each(fn resource -> router(Module.concat(resource, Router)) end)
    end
  end
end
