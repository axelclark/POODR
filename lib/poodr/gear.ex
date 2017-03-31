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

defmodule POODR.Wheel do
  use GenServer

  alias POODR.Wheel

  defstruct rim: :none, tire: :none

  # Client API

  def start_link(%{rim: rim, tire: tire}) do
    GenServer.start_link(__MODULE__, %Wheel{rim: rim, tire: tire})
  end

  def diameter(wheel) when is_pid wheel do
    GenServer.call(wheel, {:diameter})
  end

  def circumference(wheel) when is_pid wheel do
    GenServer.call(wheel, {:circumference})
  end

  # Server Callbacks

  def init(wheel) do
    {:ok, wheel}
  end

  def handle_call({:diameter}, _from, state) do
    {:reply, calc_diameter(state), state}
  end

  def handle_call({:circumference}, _from, state) do
    {:reply, calc_circumference(state), state}
  end

  # Helper Functions

  def calc_diameter(wheel) do
    wheel.rim + (wheel.tire * 2)
  end

  def calc_circumference(wheel) do
    calc_diameter(wheel) * :math.pi()
  end
end
