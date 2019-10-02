defmodule My_program do
  def main([]) do
    IO.puts("Input format: ./my_program numNodes topology algorithm")
  end


  def main(args) do
    {numNodes, topology, algorithm} = {String.to_integer(hd(args)), Enum.at(args, 1), Enum.at(args, 2)}

    Process.flag :trap_exit, true
    Proj2.NetworkManager.start_link()
    Proj2.Observer.start_link(self())
    # IO.inspect Proj2.Messenger

    {:ok, nodes} =
    case algorithm do
        "gossip"   -> Proj2.NetworkManager.spawnNodes(Proj2.Messenger, List.duplicate([], numNodes))
        "push-sum" -> Proj2.NetworkManager.spawnNodes(Proj2.PushSum, (for n <- 1..numNodes, do: [n]))
    end
    :ok = Proj2.Observer.monitor_network(Proj2.NetworkManager)

    # IO.inspect nodes

    case {algorithm, Proj2.startProgram(nodes, topology, algorithm)} do
    {"gossip", {:ok, count}}               -> IO.puts "Successfully converged: #{count} messages sent."
    {"push-sum", {:ok, count, {min, max}}} -> IO.puts "Successfully converged: #{count} messages sent, within (#{min}, #{max})."
    {_, :timeout}                          -> IO.puts "Program terminated: Timeout."
    end
  end

end