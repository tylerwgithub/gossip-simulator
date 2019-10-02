defmodule Proj2.Observer do
  @moduledoc """
  Documentation for Proj2.Observer
  """
  
  use GenServer

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
  

  @impl true
  def init(from) do
    {:ok, %{pids: %{}, from: from, data: [], converged: :false}}
  end

  @impl true
  # TY
  def handle_call({:monitor, sup}, _from, state) do 
    {:reply, :ok, Map.put(state, :pids, DynamicSupervisor.which_children(sup)
      |> Map.new(fn {:undefined, pid, _type, _modules} -> {pid, :ok} end))}
    
  end

  @impl true
  def handle_call(:converged?, _from, state), do: {:reply, Map.get(state, :converged?), state}
  

  #TY
  @impl true
  def handle_cast({:converged, pid, datum}, %{pids: pids} = state) do
    {:noreply,
	  Map.put(state, :pids, Map.put(pids, pid, :converged))
	    |> Map.update!(:data, fn data -> [datum] ++ data end),
	  {:continue, :check_convergence}}
  end
  
  #TY
  @impl true
  def handle_info(:timeout, %{from: from} = state) do
	{:noreply, send(from, :timeout), state}
  end
  
  # TY
  @impl true
  def handle_continue(:check_convergence, %{pids: pids, from: from, data: data} = state) do
    values = Map.values(Map.get(state, :pids))
    con = ifConverged(values)
    if con do
	  send from, {:converged, data,
	               Task.async_stream(Map.keys(pids), fn pid -> Proj2.GossipNode.get(pid, :sent, :infinity) end)
				     |> Enum.reduce(0, fn {:ok, n}, acc -> n + acc end)}
	  end

	{:noreply, state, 10_000}
  end
  
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