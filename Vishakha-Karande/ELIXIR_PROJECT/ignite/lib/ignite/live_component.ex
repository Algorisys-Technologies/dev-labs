defmodule Ignite.LiveComponent do
  @callback mount(props :: map()) :: {:ok, map()}
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) ::
              {:noreply, map()}
  @callback render(assigns :: map()) :: any()

  @optional_callbacks [mount: 1, handle_event: 3]

  defmacro __using__(_opts) do
    quote do
      import Ignite.LiveView # Allow using sigil_L, etc
      @behaviour Ignite.LiveComponent
    end
  end
end
