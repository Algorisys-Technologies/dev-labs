defmodule Ignite.LiveView do
  @doc "Called when the LiveView process starts. Returns initial assigns."
  @callback mount(params :: map(), session :: map()) :: {:ok, map()}

  @doc "Called when the browser sends an event (click, form submit, etc.)."
  @callback handle_event(event :: String.t(), params :: map(), assigns :: map()) ::
              {:noreply, map()}

  @doc "Returns the HTML string for the current assigns."
  @callback render(assigns :: map()) :: String.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Ignite.LiveView
    end
  end
end
