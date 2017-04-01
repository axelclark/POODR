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
