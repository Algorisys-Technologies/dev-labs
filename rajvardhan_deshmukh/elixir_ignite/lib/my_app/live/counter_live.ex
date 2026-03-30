defmodule MyApp.CounterLive do
  @moduledoc """
  A simple live counter — demonstrates real-time updates without page refreshes.
  """

  use Ignite.LiveView

  @impl true
  def mount(_params, _session) do
    {:ok, %{count: 0}}
  end

  @impl true
  def handle_event("increment", _params, assigns) do
    {:noreply, %{assigns | count: assigns.count + 1}}
  end

  @impl true
  def handle_event("decrement", _params, assigns) do
    {:noreply, %{assigns | count: assigns.count - 1}}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div id="counter">
      <!-- The dynamic part of our page -->
      <h2><%= @count %></h2>
      <%= if @count < 0 do %>
        <p style="color: red;">Count is negative! (FEEx block demo)</p>
      <% end %>
      
      <div>
        <button ignite-click="decrement" style="font-size: 1.5em; padding: 10px 20px;">-</button>
        <button ignite-click="increment" style="font-size: 1.5em; padding: 10px 20px;">+</button>
      </div>

      <div style="margin-top: 30px;">
        <button ignite-click="crash" style="background-color: #ff4444; color: white; border: none; padding: 5px 10px; border-radius: 3px;">
          Simulate Crash
        </button>
      </div>

      <!-- Navigation Links -->
      <div style="margin-top: 30px; font-size: 0.9em;">
        <h4>Navigation</h4>
        <a href="/counter" ignite-navigate="/counter">Counter</a> | 
        <a href="/dashboard" ignite-navigate="/dashboard">Dashboard</a> | 
        <a href="/shared-counter" ignite-navigate="/shared-counter">Shared Counter</a>
      </div>
    </div>
    """
  end
end
