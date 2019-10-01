defmodule Proj2.Observer do
  @moduledoc """
  Documentation for Proj2.Observer
  """
  
  use GenServer
  
  ## Client API
  
  @doc """
  Starting and linking the GenServer process.
  Initializing a node in the network.
  The state holds three elements: 
  the convergence number, 
  number of received messages at the start 
  and the neighbors of a node.
  """
  def start_link(from) do
    GenServer.start_link(__MODULE__, from, name: __MODULE__)
    # IO.inspect 
  end
  
  def monitor_network(sup) do
    GenServer.call(__MODULE__, {:monitor, sup})
  end
  
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end
  
  ## Server Callbacks

  @doc """
  GenServer initialization.
  """
  @impl true
  def init(from) do
    {:ok, %{pids: %{}, from: from, data: [], converged: :false}}
  end

  @doc """
  Handle request to monitor network, and initialize mapping of node states.
  """
  @impl true
  # TY
  def handle_call({:monitor, sup}, _from, state) do 
    {:reply, :ok, Map.put(state, :pids, DynamicSupervisor.which_children(sup)
      |> Map.new(fn {:undefined, pid, _type, _modules} -> {pid, :ok} end))}
    # {:reply, :ok, Map.put(state, :pids,
    #   DynamicSupervisor.which_children(sup)
	  #   |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
	  #   |> Map.new(fn pid -> {pid, :ok} end))}
  end
  
  @doc """
  Handle request to check if network has converged.
  """
  @impl true
  def handle_call(:converged?, _from, state), do: {:reply, Map.get(state, :converged?), state}
  
  @doc """
  Record convergence of monitored nodes.
  """
  #TY
  @impl true
  def handle_cast({:converged, pid, datum}, %{pids: pids} = state) do
    # Map.put(state, :data, [datum])
    # Map.put(pids, pid, :converged)
    # Map.put(state, :pids, pids)
    # Map.update!(state, :data, fn data -> [datum] ++ data end)
    # IO.inspect state
    {:noreply,
	  Map.put(state, :data, [datum] ++ Map.get(state, :date))
	    |> Map.put(:pids, Map.put(pids, pid, :converged)),
	 {:continue, :check_convergence}}
   

  #   {:noreply,
	#   Map.update!(state, :data, fn data -> [datum] ++ data end)
	#     |> Map.put(:pids, Map.put(pids, pid, :converged)),
	#  {:continue, :check_convergence}}

  #   {:noreply,
	#   Map.put(state, :pids, Map.put(pids, pid, :converged))
	#     |> Map.update!(:data, fn data -> [datum] ++ data end),
	#  {:continue, :check_convergence}}
  end
  
  @doc """
  Handle timeout while waiting for convergence.
  """
  #TY
  @impl true
  def handle_info(:timeout, %{from: from} = state) do
    # IO.inspect from
    # send(from, :timeout)
	{:noreply, send(from, :timeout), state}
  end
  
  @doc """
  Check complete convergence of monitored nodes.
  """
  # TY
  @impl true
  def handle_continue(:check_convergence, %{pids: pids, from: from, data: data} = state) do
    values = Map.values(Map.get(state, :pids))
    con = ifConverged(values)
    if con do
	  send from, {:converged, data,
	               Task.async_stream(Map.keys(pids), fn pid -> Proj2.GossipNode.get(pid, :sent, :infinity) end)
				     |> Enum.reduce(0, fn {:ok, n}, acc -> n + acc end)}
                # Task.async_stream(Map.keys(pids), fn pid -> Proj2.GossipNode.get(pid, :sent, :infinity) end, timeout: 10*length(Map.keys(pids)))
            #  |> Enum.map(fn {:ok, n} -> n end)
	          #        |> Enum.sum()}
	  end

	{:noreply, state, 10_000}
  end
  
  # defp converged?(nodes) when length(nodes) == 0, do: :true
  
  # defp converged?(nodes), do: (if hd(nodes) == :converged, do: converged?(tl(nodes)), else: :false)
#TY
  defp ifConverged([head | tail]) do
    if head == :converged do
      ifConverged(tail)
    else
      :false
    end
  end

  defp ifConverged([]) do
    :true
  end
end