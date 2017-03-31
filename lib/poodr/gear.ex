defmodule POODR.Gear do
  alias POODR.{Gear, Wheel}

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

defmodule POODR.Wheel do
  alias POODR.Wheel

  defstruct rim: :none, tire: :none

  def start_link(rim, tire) do
    Agent.start_link(fn -> %Wheel{rim: rim, tire: tire} end)
  end

  def tire(wheel), do: Agent.get(wheel, &(&1.tire))
  def rim(wheel),  do: Agent.get(wheel, &(&1.rim))

  def diameter(wheel) do
    rim(wheel) + (tire(wheel) * 2)
  end

  def circumference(wheel) do
    diameter(wheel) * :math.pi()
  end
end
