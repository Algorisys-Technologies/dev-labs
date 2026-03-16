defmodule Ignite.LiveComponent do
  @callback mount(props :: map()) :: {:ok, map()}
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) ::
              {:noreply, map()}
  @callback render(assigns :: map()) :: String.t()

  @optional_callbacks [mount: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour Ignite.LiveComponent
    end
  end
end
