defmodule Trip.Application do
  use Application

  def start(_type, _args) do
    PreparersSupervisor.start_link()
    Trip.SystemsSupervisor.start_link()
  end
end
