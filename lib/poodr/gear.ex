defmodule POODR.Gear do
  use GenServer

  alias POODR.Gear

  defstruct chainring: :none, cog: :none, wheel: :none

  #Client API

  def start_link(%{chainring: chainring, cog: cog, wheel: wheel}) do
    GenServer.start_link(__MODULE__,
      %Gear{chainring: chainring, cog: cog, wheel: wheel}
    )
  end

  def ratio(gear) when is_pid gear do
    GenServer.call(gear, {:ratio})
  end

  def gear_inches(gear) when is_pid gear do
    GenServer.call(gear, {:gear_inches})
  end

  def cog(gear) when is_pid gear do
    GenServer.call(gear, {:cog})
  end

  def chainring(gear) when is_pid gear do
    GenServer.call(gear, {:chainring})
  end

  #Server Callbacks

  def init(gear) do
    {:ok, gear}
  end

  def handle_call({:chainring}, _from, state) do
    {:reply, state.chainring, state}
  end

  def handle_call({:cog}, _from, state) do
    {:reply, state.cog, state}
  end

  def handle_call({:ratio}, _from, state) do
    {:reply, calc_ratio(state), state}
  end

  def handle_call({:gear_inches}, _from, state) do
    {:reply, calc_gear_inches(state), state}
  end

  # Helper Functions

  defp calc_ratio(gear) when is_map gear do
    gear.chainring / gear.cog
  end

  defp calc_gear_inches(gear) when is_map gear do
    calc_ratio(gear) * diameter(gear.wheel)
  end

  defp diameter(wheel) when is_pid wheel do
    GenServer.call(wheel, {:diameter})
  end
end
