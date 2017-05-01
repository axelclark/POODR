defmodule TripSupervisor do
  use Supervisor

  def start_link() do
    IO.puts "Starting TripSupervisor"

    Supervisor.start_link(
      __MODULE__,
      nil,
      name: :trips_supervisor
    )
  end

  def start_child(name, num_bikes) do
    Supervisor.start_child(
      :trips_supervisor,
      [name, num_bikes]
    )
  end

  def init(_) do
    children = [
      supervisor(SingleTripSupervisor, []),
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end

defmodule SingleTripSupervisor do
  use Supervisor

  def start_link(name, num_bikes) do
    IO.puts "Starting SingleTripSupervisor"

    Supervisor.start_link(
      __MODULE__,
      {name, num_bikes},
      name: via_tuple(name)
    )
  end

  defp via_tuple(name) do
    {:via, Registry, {:process_registry, {:trip_sup, name}}}
  end

  def init({name, num_bikes}) do
    children = [
      supervisor(Trip.BikeSupervisor, [name]),
      worker(Trip, [name, num_bikes]),
    ]

    supervise(children, strategy: :one_for_all)
  end
end

defmodule PreparersSupervisor do
  use Supervisor

  def start_link() do
    IO.puts "Starting PreparersSupervisor"

    Supervisor.start_link(
      __MODULE__,
      nil
    )
  end

  def init(_) do
    children = [
      supervisor(Registry, [:duplicate, Registry.Preparers]),
      worker(Mechanic, []),
    ]
    supervise(children, strategy: :rest_for_one)
  end
end


defmodule Trip.SystemsSupervisor do
  use Supervisor

  def start_link() do
    IO.puts "Starting Trip.SystemSupervisor"

    Supervisor.start_link(
      __MODULE__,
      nil
    )
  end

  def init(_) do
    children = [
      supervisor(Registry, [:unique, :process_registry], id: :proc),
      supervisor(TripSupervisor, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end


defmodule Trip.BikeSupervisor do
  use Supervisor

  def start_link(name) do
    IO.puts "Starting Trip.BikeSupervisor"

    Supervisor.start_link(
      __MODULE__,
      nil,
      name: via_tuple(name)
    )
  end

  defp via_tuple(name) do
    {:via, Registry, {:process_registry, {:bike_sup, name}}}
  end

  def start_child(name, bike_id) do
    Supervisor.start_child(
      via_tuple(name),
      [bike_id]
    )
  end

  def init(_) do
    children = [
      worker(Bicycle, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
