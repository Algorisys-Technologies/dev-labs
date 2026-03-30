defmodule Ignite.LiveComponent do
  @moduledoc """
  Defines the LiveComponent behaviour for reusable stateful widgets.

  Callbacks:
  - mount(props): Optional. Initializes state from props.
  - handle_event(event, params, assigns): Handles clicks/events from the browser.
  - render(assigns): Returns the HTML string.
  """

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
