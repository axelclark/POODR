defmodule POODR.Agent.Wheel do
  alias POODR.Agent.Wheel

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
