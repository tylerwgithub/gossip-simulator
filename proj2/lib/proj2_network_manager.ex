defmodule Proj2.NetworkManager do
  @moduledoc """
  Documentation for Proj2.NetworkManager
  """
  use DynamicSupervisor
  
  alias Proj2.GossipNode, as: Node
  
  ## Client API
  
  @doc """
  Starts and links the Network Manager process.
  """
  def start_link(args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
    # IO.inspect self()
  end
  
  @doc """
  Starts a new GossipNode under the NetworkManager.
  
  start_child/4 takes all the parameters required to initialize a GossipNode
  start_child/2 takes a module name which contains the required functions, as well as the parameters to pass to the init function.
  """
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
  
  # def start_child(module, args \\ []) do
  #   IO.inspect module

  #   start_child(apply(module, :init, args),
	#           &(apply(module, :tx_fn, [&1])),
	# 	      &(apply(module, :rcv_fn, [&1, &2])),
	# 		  &(apply(module, :mode_fn, [&1, &2, &3])))
  # end
  
  @doc """
  Starts multiple new GossipNodes under the NetworkManager.
  
  
  """
  # def start_children(data, tx_fn, rcv_fn, mode_fn) do
  # # IO.inspect tx_fn
  #   data
	#   |> Enum.map(fn datum -> start_child(datum, tx_fn, rcv_fn, mode_fn) end)
	#   |> Enum.reduce({:ok, []}, fn {:ok, pid}, {:ok, pids} -> {:ok, pids ++ [pid]} end)
    
  # end
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

    # start_children(Enum.map(args, &(apply(module, :init, &1))),
    #            &(apply(module, :tx_fn, [&1])),
		#          &(apply(module, :rcv_fn, [&1, &2])),
		# 	     &(apply(module, :mode_fn, [&1, &2, &3])))
    
  end
  
  @doc """
  Creates a network across the active GossipNodes by assigning neighbors using the desired topology function.
  
  ## Parameters
    - sup:         PID of the NetworkManager
    - topology_fn: Function which is invoked on the list of active GossipNodes and returns a list of tuples in the form {node, [neighbors]}
  """
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
  
  # def reset(module, data) do
  #   nodes =
	#   DynamicSupervisor.which_children(__MODULE__)
	#     |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	# :ok =
	#   Task.async_stream(nodes, Node, :stop, [])
	#     |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  #   Process.sleep(Application.get_env(:proj2, :delay) * 3)  # Make sure all :transmit messages are cleared
	# Enum.map(data, &(apply(module, :init, &1)))
	#   |> Enum.zip(nodes)
	#   |> Task.async_stream(fn {data, node} -> Node.reset(node, data) end)
	#   |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  # end
  
  # def kill_children() do
  #   DynamicSupervisor.which_children(__MODULE__)
	#   |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	#   |> Task.async_stream(fn pid -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
	#   # |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)

  #   # DynamicSupervisor.which_children(__MODULE__)
	#   # |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	#   # |> Task.async_stream(fn pid -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
	#   # |> Enum.reduce(:ok, fn {:ok, :ok}, :ok -> :ok end)
  # end
  
  ## Server Callbacks
  
  @impl true
  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end
end