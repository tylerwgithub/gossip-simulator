defmodule Proj2.NetworkManager do
  @moduledoc """
  Documentation for Proj2.NetworkManager
  """
  use DynamicSupervisor
  
  alias Proj2.GossipNode, as: Node
  
  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
    # IO.inspect self()
  end
  
  #TY
  def spawnNodes(module, args) do
    # data = Enum.map(args, &module.init(&1))
    sd = &module.sendFn(&1)
    rcv = &module.receiveFn(&1, &2)
    mode = &module.modeFn(&1, &2, &3)
    Enum.map(args, &module.init(&1))
	  |> Enum.map(fn datum -> nodeConfig(datum, sd, rcv, mode) end)
	  |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, [pid] ++ pids} end)

  end

  def nodeConfig(data, sendFn, receiveFn, modeFn) do
    DynamicSupervisor.start_child(__MODULE__, Supervisor.child_spec(
	  {Node,
	    %{mode:      :passive,
		  data:      data,
		  neighbors: [],
		  sent:      0,
		  sendFn:     sendFn,
		  receiveFn:    receiveFn,
		  modeFn:   modeFn}
      }, restart: :temporary))
  end
  

  #TY
  def linkNodes(getTopology) do
    [head | _] = DynamicSupervisor.which_children(__MODULE__)
	  |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	  |> getTopology.()
	  |> Task.async_stream(fn {node, neighbors} -> Node.update(node, :neighbors, fn _ -> neighbors end) end)
	  |> Enum.map(fn _ -> :ok end)
    head
    # |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  end
  

  @impl true
  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end