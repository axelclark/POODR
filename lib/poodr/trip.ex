defmodule Trip do
  use GenServer

  defstruct bicycles: :none, bikes_ready: 0, name: :none

  # Client API

  def start_link(name, num_bikes) do
    IO.puts "Starting Trip for #{name}"

    GenServer.start_link(
      __MODULE__,
      {name, num_bikes},
      name: via_tuple(name)
    )
  end

  defp via_tuple(name) do
    {:via, Registry, {:process_registry, {:trip, name}}}
  end

  def new(name, num_bikes) do
    TripSupervisor.start_child(name, num_bikes)
  end

  def ready?(name) do
    GenServer.call(via_tuple(name), :trip_ready?)
  end

  def prepare(name) do
    GenServer.cast(via_tuple(name), :prepare)
  end

  # Server Callbacks

  def init({name, num_bikes}) do
    trip = %Trip{name: name}

    bikes =
      for bike <- 1..num_bikes do
        IO.puts "creating bike: #{bike}"
        bike_id = "#{name} bike: #{bike}"
        {:ok, _bike} =
          Trip.BikeSupervisor.start_child(name, bike_id)
        bike_id
      end

    {:ok, %Trip{trip | bicycles: bikes}}
  end

  def handle_call(:trip_ready?, _from, state) do
    {:reply, trip_ready?(state), state}
  end

  def handle_cast(:prepare, state) do
    preparers = get_preparers()
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

  defp get_preparers() do
    Registry.Preparers
    |> Registry.lookup(:preparer)
    |> Enum.map(fn({pid, _key}) -> pid end)
  end

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
    IO.puts "Starting Mechanic"

    GenServer.start_link(__MODULE__, nil, name: :mechanic)
  end

  # Server Callbacks

  def init(_) do
    # Registry.start_link(:duplicate, Registry.Preparers)
    Registry.register(Registry.Preparers, :preparer, :mechanic)
    {:ok, %{}}
  end

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
      Bicycle.service(bike)
      Map.put(state, bike, trip)
    end
  end
end

defmodule Bicycle do
  use GenServer

  defstruct ready?: false, type: "mountain", id: :none

  # Client API

  def start_link(id) do
    IO.puts "Starting bike: #{id}"

    GenServer.start_link(
      __MODULE__,
      id,
      name: via_tuple(id)
    )
  end

  defp via_tuple(id) do
    {:via, Registry, {:process_registry, {:bike, id}}}
  end

  def service(bike) do
    GenServer.cast(via_tuple(bike), {:service, self()})
  end

  # Server Callbacks

  def init(name) do
    {:ok, %Bicycle{id: name}}
  end

  def handle_cast({:service, caller}, state) do
    send(caller, {:bicycle_serviced, state.id})
    {:noreply, %Bicycle{state | ready?: true}}
  end
end
