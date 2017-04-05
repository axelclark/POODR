defmodule Trip do
  use GenServer

  defstruct bicycles: :none, bikes_ready: 0

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, %Trip{})
  end

  def ready?(trip) when is_pid trip do
    GenServer.call(trip, :trip_ready?)
  end

  def prepare(trip, preparers) do
    GenServer.cast(trip, {:prepare, preparers})
  end

  # Server Callbacks

  def init(trip) do
    {:ok, bike1} = Bicycle.start_link
    {:ok, bike2} = Bicycle.start_link
    bicycles = [bike1, bike2]
    {:ok, %Trip{trip | bicycles: bicycles}}
  end

  def handle_call(:trip_ready?, _from, state) do
    case trip_ready?(state) do
      true  -> {:reply, true, state}
      false -> {:reply, false, state}
    end
  end

  def handle_cast({:prepare, preparers}, state) do
    prepare_trip(preparers)
    {:noreply, state}
  end

  def handle_cast({:bicycles, caller}, state) do
    send(caller, {:bicycles, state.bicycles, self()})
    {:noreply, state}
  end

  def handle_info({:bike_prepped, _bike}, state) do
    {:noreply, %Trip{state | bikes_ready: state.bikes_ready + 1}}
  end

  # Helper Functions

  defp prepare_trip(preparers) do
    Enum.each preparers, fn preparer ->
      request_prep(preparer)
    end
  end

  defp request_prep(preparer) do
    GenServer.cast(preparer, {:prepare_trip, self()})
  end

  defp trip_ready?(%{bicycles: bicycles, bikes_ready: bikes_ready}) do
    length(bicycles) <= bikes_ready
  end
end

defmodule Mechanic do
  use GenServer

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__,%{})
  end

  # Server Callbacks

  def handle_cast({:prepare_trip, trip}, state) do
    request_bicycles(trip)
    {:noreply, state}
  end

  def handle_info({:bicycles, bicycles, trip}, state) do
    {:noreply, service_bicycles(bicycles, trip, state)}
  end

  def handle_info({:bicycle_serviced, bike}, state) do
    {trip, new_state} = Map.pop(state, bike)
    send(trip, {:bike_prepped, bike})
    {:noreply, new_state}
  end

  # Helper Functions

  def request_bicycles(trip) do
    GenServer.cast(trip, {:bicycles, self()})
  end

  defp service_bicycles(bicycles, trip, state) do
    Enum.reduce bicycles, state, fn bike, state ->
      service_bike(bike)
      Map.put(state, bike, trip)
    end
  end

  defp service_bike(bike) do
    GenServer.cast(bike, {:service, self()})
  end
end

defmodule Bicycle do
  use GenServer

  defstruct ready?: false, type: "mountain"

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__,%Bicycle{})
  end

  # Server Callbacks

  def init(bicycle) do
    {:ok, bicycle}
  end

  def handle_cast({:service, caller}, state) do
    send(caller, {:bicycle_serviced, self()})
    {:noreply, %Bicycle{state | ready?: true}}
  end
end
