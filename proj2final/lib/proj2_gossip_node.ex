defmodule Proj2.GossipNode do
  @moduledoc """
  GossipNode sends and receives gossip.
  """  
  use GenServer
  
  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end
  
  def transmit(node) do
    # IO.inspect node
    send node, :transmit
  end
  
  def stop(node) do
    update(node, :mode, fn _ -> :stopped end)
  end
  
  def reset(node, data) do
    update(node,
	      [{:mode, fn _ -> :passive end},
		   {:data, fn _ -> data end}])
  end
  

  def startGossip(node, gossip) do
    GenServer.cast(node, {:gossip, gossip})
  end
  
  def get(node, key, timeout \\ 5000) do
    GenServer.call(node, {:get, key}, timeout)
  end
  
  def update(node, key_fun) when is_list(key_fun) do
    GenServer.call(node, {:update, key_fun})
  end
  
  def update(node, key, fun) do
    GenServer.call(node, {:update, key, fun})
  end
  
  @impl true
  def init(state) do
    {:ok, state}
  end
  
  def handle_call({:get, keys}, _from, state) when is_list(keys) do
    {:reply, Enum.map(keys, &(Map.get(state, &1))), state}
  end
  
  def handle_call({:get, key}, _from, state), do: {:reply, Map.get(state, key), state}
  
  @impl true
  def handle_call({:update, key_fun}, _from, state) when is_list(key_fun) do
    {:reply, :ok, Enum.reduce(key_fun, state, &(Map.update!(&2, elem(&1, 0), elem(&1, 1))))}
  end
  
  def handle_call({:update, key, fun}, _from, state) do
   {:reply, :ok, Map.update!(state, key, fun)}
  end

  @impl true
  def handle_info(_, %{mode: :stopped} = state), do: {:noreply, state}
  
  def handle_info(:transmit, %{neighbors: neighbors} = state) when length(neighbors) == 0, do: {:noreply, Map.put(state, :mode, :stopped)}
  
  def handle_info(:transmit, %{mode: mode, data: data, neighbors: neighbors, sent: sent, sendFn: sendFn, modeFn: modeFn} = state) do
    {data, gossip} = sendFn.(data)
    startGossip(Enum.random(neighbors), gossip)
	Process.send_after(self(), :transmit, get_delay())
	{:noreply,
      state
	   |> Map.put(:mode, modeFn.(:send, mode, data))
	   |> Map.put(:data, data)
	   |> Map.put(:sent, sent+1),
	  {:continue, mode}}
  end
  

  @impl true
  def handle_cast(_, %{mode: :stopped} = state), do: {:noreply, state}
  
  def handle_cast({:gossip, gossip}, %{mode: mode, data: data, receiveFn: receiveFn, modeFn: modeFn} = state) do
	if mode == :passive, do: send(self(), :transmit)
	{:noreply,
	  state
	    |> Map.put(:mode, modeFn.(:receive, (if mode == :passive, do: :active, else: mode), data))
	    |> Map.put(:data, receiveFn.(data, gossip)),
	  {:continue, mode}}
  end
  

  @impl true
  def handle_continue(prev_mode, %{mode: mode} = state) when mode == prev_mode, do: {:noreply, state}
  
  def handle_continue(prev_mode, %{mode: mode, data: data} = state)
  when mode == :converged
  or   mode == :stopped and prev_mode != :converged do
    :ok = GenServer.cast(Proj2.Observer, {:converged, self(), data})
	{:noreply, state}
  end
  
  def handle_continue(_, state), do: {:noreply, state}
  
  defp get_delay() do
    :rand.uniform()
	  |> :math.exp()
	  |> Kernel.*(Application.get_env(:proj2, :delay))
	  |> trunc()
  end
end