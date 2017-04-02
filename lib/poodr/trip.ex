defmodule Trip do
  use GenServer

  defstruct bicycles: :none, customer: :none, lunches: 0

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, %Trip{})
  end

  def bicycles(trip) do
    GenServer.call(trip, :bicycles)
  end

  def add_customer(trip, customer) do
    GenServer.call(trip, {:add_customer, customer})
  end

  # Server Callbacks

  def init(trip) do
    {:ok, bike1} = Bicycle.start_link
    {:ok, bike2} = Bicycle.start_link
    bicycles = [bike1, bike2]
    {:ok, %Trip{trip | bicycles: bicycles}}
  end

  def handle_call(:bicycles, _from, state) do
    {:reply, state.bicycles, state}
  end

  def handle_call(:customer, _from, state) do
    {:reply, state.customer, state}
  end

  def handle_call({:add_customer, customer}, _from, state) do
    {:reply, {:ok, customer}, %Trip{state | customer: customer}}
  end

  def handle_call({:add_lunches, quantity}, _from, state) do
    {:reply, {:ok, quantity}, update_lunches(state, quantity)}
  end

  defp update_lunches(state, quantity) do
    lunches = state.lunches + quantity
    %Trip{state | lunches: lunches}
  end
end

defmodule TripCoordinator do
  use GenServer

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def prepare(coordinator, trip, preparers) do
    GenServer.call(coordinator, {:prepare, trip, preparers})
  end

  # Server Callbacks

  def init(state) do
    {:ok, state}
  end

  def handle_call({:prepare, trip, preparers}, _from, state) do
    prepare_trip(trip, preparers)
    {:reply, :ok, state}
  end

  # Helper Functions

  defp prepare_trip(trip, preparers) do
    Enum.each(preparers, fn preparer ->
      GenServer.call(preparer, {:prepare_trip, trip})
    end)
  end
end

defmodule Mechanic do
  use GenServer

  # Client API

  def start_link() do
    GenServer.start_link(__MODULE__,[])
  end

  # Server Callbacks

  def handle_call({:prepare_trip, trip}, _from, state) do
    prepare_trip(trip)
    {:reply, :ok, state}
  end

  # Helper Functions

  defp prepare_trip(trip) do
    bicycles = bicycles(trip)
    Enum.each bicycles, fn bicycle ->
      prepare_bicycle(bicycle)
    end
  end

  def bicycles(trip) do
    GenServer.call(trip, :bicycles)
  end

  defp prepare_bicycle(bicycle) do
    GenServer.call(bicycle, :service)
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

  def handle_call(:service, _from, state) do
    {:reply, :ok, %Bicycle{state | ready?: true}}
  end
end

defmodule Caterer do
  use GenServer

  defstruct food_storage: :none

  def start_link() do
    GenServer.start_link(__MODULE__, %Caterer{})
  end

  def init(caterer) do
    {:ok, food_storage} = FoodStorage.start_link()
    {:ok, %Caterer{caterer | food_storage: food_storage}}
  end

  def handle_call({:prepare_trip, trip}, _from, state) do
    {:reply, prepare_trip(state.food_storage, trip), state}
  end

  def prepare_trip(food_storage, trip) do
    trip
    |> customer
    |> people
    |> get_lunches(food_storage)
    |> add_lunches(trip)
  end

  def customer(trip) do
    GenServer.call(trip, :customer)
  end

  def people(customer) do
    GenServer.call(customer, :people)
  end

  def get_lunches(quantity, food_storage) do
    GenServer.call(food_storage, {:get_lunches, quantity})
  end

  def add_lunches(quantity, trip) do
    GenServer.call(trip, {:add_lunches, quantity})
  end
end

defmodule FoodStorage do
  use GenServer

  defstruct lunches: 100

  def start_link() do
    GenServer.start_link(__MODULE__, %FoodStorage{})
  end

  def init(food_storage) do
    {:ok, food_storage}
  end

  def handle_call(:lunches, _from, state) do
    {:reply, state.lunches, state}
  end

  def handle_call({:get_lunches, quantity}, _from, state) do
    lunches = state.lunches - quantity
    new_state = %FoodStorage{state | lunches: lunches}
    {:reply, quantity, new_state}
  end
end

defmodule Customer do
  defstruct people: 0

  def start_link(people) do
    GenServer.start_link(__MODULE__,%Customer{people: people})
  end

  def init(customer) do
    {:ok, customer}
  end

  def handle_call(:people, _from, state) do
    {:reply, state.people, state}
  end
end
