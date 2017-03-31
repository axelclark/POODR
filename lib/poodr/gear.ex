defmodule POODR.Gear do
  use GenServer

  alias POODR.Gear

  defstruct chainring: :none, cog: :none, rim: :none, tire: :none

  def start_link(chainring, cog, rim, tire) do
    GenServer.start_link(__MODULE__, [chainring, cog, rim, tire])
  end

  def init([chainring, cog, rim, tire]) do
    {:ok, %Gear{chainring: chainring, cog: cog, rim: rim, tire: tire}}
  end

  def handle_call({:chainring}, _from, state) do
    {:reply, state.chainring, state}
  end
end
