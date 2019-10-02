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
  
  def start_child(data, tx_fn, rcv_fn, mode_fn) do
    DynamicSupervisor.start_child(__MODULE__, Supervisor.child_spec(
	  {Node,
	    %{mode:      :passive,
		  data:      data,
		  neighbors: [],
		  sent:      0,
		  tx_fn:     tx_fn,
		  rcv_fn:    rcv_fn,
		  mode_fn:   mode_fn}
      }, restart: :temporary))
  end
  
 
  #TY
  def start_children(module, args) do
    # data = Enum.map(args, &module.init(&1))
    tx = &module.tx_fn(&1)
    rcv = &module.rcv_fn(&1, &2)
    mode = &module.mode_fn(&1, &2, &3)
    # start_children(data, tx, rcv, mode)
    Enum.map(args, &module.init(&1))
	  |> Enum.map(fn datum -> start_child(datum, tx, rcv, mode) end)
	  |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, [pid] ++ pids} end)

  end
  

  #TY
  def set_network(topology_fn) do
    [head | _] = DynamicSupervisor.which_children(__MODULE__)
	  |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	  |> topology_fn.()
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