defmodule POODR.Agent.Gear do
  alias POODR.Agent.{Gear, Wheel}

  defstruct chainring: :none, cog: :none, wheel: :none

  def start_link(chainring, cog, wheel) do
    Agent.start_link(fn ->
      %Gear{chainring: chainring, cog: cog, wheel: wheel}
    end)
  end

  def chainring(gear), do: Agent.get(gear, &(&1.chainring))
  def cog(gear),       do: Agent.get(gear, &(&1.cog))
  def wheel(gear),     do: Agent.get(gear, &(&1.wheel))

  def ratio(gear) do
    chainring(gear) / cog(gear)
  end

  def gear_inches(gear) do
    ratio(gear) * Wheel.diameter(wheel(gear))
  end
end
