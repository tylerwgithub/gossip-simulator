defmodule Proj2.Messenger do
  @moduledoc """
  Defines a simple message-passing implementation, where messages take the form of atoms.
  
  ## Gossip content
  
  Each node maintains a map of messages received and the number of times each has been received. When gossiping, the node sends a list of all received messages.
  When a new message is received, it is added to the map. The message's counter is incremented each time the message is received again.
  
  ## Convergence
  
  When the counter for all messages in the map exceeds a certain value, the node converges.
  """
  #TY
  def init([]), do: %{}
    # IO.inspect
  
  def sendFn(msgs) do
    {msgs, Map.keys(msgs)}
  end
  
  def receiveFn(msgs, msg) when length(msg) == 0, do: msgs
  
  def receiveFn(msgs, msg) do
    Map.update(receiveFn(msgs, tl(msg)), hd(msg), 1, &(&1+1))
  end
  
  def modeFn(:send, mode, _msgs), do: mode
  
  def modeFn(:receive, :converged, msgs) do
    Enum.reduce_while(Map.values(msgs), :converged, fn x, mode ->
	  if x < Application.get_env(:proj2, :msg_count), do: {:cont, mode}, else: {:halt, :stopped}
	end)
  end
  
  def modeFn(:receive, _mode, _msgs), do: :converged

end