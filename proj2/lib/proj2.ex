defmodule Proj2 do
 
  def checkConvergence(nodes, topology, "gossip") do
    :ok = Proj2.NetworkManager.set_network(
      case topology do
        "full"   -> &Proj2.Topology.full/1
        "line"   -> &(Proj2.Topology.grid(&1, 1))
        "rand2D" -> &(Proj2.Topology.rand2d(&1, 0.1))
        "3Dtorus" -> &(Proj2.Topology.grid(&1, 3))
        "honeycomb" -> &(Proj2.Topology.honeycomb(&1))
        "randhoneycomb" -> &(Proj2.Topology.randhoneycomb(&1))
      end)

    Proj2.GossipNode.gossip(Enum.random(nodes), [:hello])
    # IO.inspect Enum.random(nodes)
	receive do
      {:converged, _data, sent} -> {:ok, sent}
      :timeout -> :timeout
    end
  end
  
  def checkConvergence(nodes, topology, "push-sum") do
    :ok = Proj2.NetworkManager.set_network(
      case topology do
        "full"   -> &Proj2.Topology.full/1
        "line"   -> &(Proj2.Topology.grid(&1, 1))
        "rand2D" -> &(Proj2.Topology.rand2d(&1, 0.1))
        "3Dtorus"  -> &(Proj2.Topology.grid(&1, 3))
        "honeycomb" -> &(Proj2.Topology.honeycomb(&1))
        "randhoneycomb" -> &(Proj2.Topology.randhoneycomb(&1))
      end)
    Proj2.GossipNode.transmit(Enum.random(nodes))
	receive do
      {:converged, data, sent} -> 
	    {:ok, sent, Enum.reduce(data, {:infinity, 0}, fn {_, _, r, _}, {min, max} -> {min(r, min), max(r, max)} end)}
      :timeout -> :timeout
    end
  end
end
