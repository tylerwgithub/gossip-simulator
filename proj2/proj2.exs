{numNodes, topology, algorithm} = {String.to_integer(hd(System.argv)), Enum.at(System.argv, 1), Enum.at(System.argv, 2)}

Proj2.NetworkManager.start_link()
Proj2.Observer.start_link(self())
# IO.inspect Proj2.Messenger

{:ok, nodes} =
  case algorithm do
    "gossip"   -> Proj2.NetworkManager.start_children(Proj2.Messenger, List.duplicate([], numNodes))
	  "push-sum" -> Proj2.NetworkManager.start_children(Proj2.PushSum, (for n <- 1..numNodes, do: [n]))
  end
:ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)

# IO.inspect nodes

case {algorithm, Proj2.checkConvergence(nodes, topology, algorithm)} do
  {"gossip", {:ok, count}}               -> IO.puts "Converged after #{count} messages."
  {"push-sum", {:ok, count, {min, max}}} -> IO.puts "Converged within (#{min}, #{max}) after #{count} messages."
  {_, :timeout}                          -> IO.puts "Timed out without converging."
end