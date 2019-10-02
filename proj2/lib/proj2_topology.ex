defmodule Proj2.Topology do

  #TY
  def full(nodes) do
    # IO.inspect nodes
    nodes |> Enum.map(fn x -> {x, nodes -- [x]} end)
	  # |> elem(0)
    # IO.inspect
  end



  def rand2d(nodes, radius) do
    nodes
	  |> add_edges()
	  |> Enum.zip(get_2dcoords(length(nodes)))
	  |> Enum.sort(&(hd(elem(&1, 1)) <= hd(elem(&2, 1))))
	  |> find_nearby(radius)
	  |> Enum.reverse()
	  |> find_nearby(radius)
	  |> Enum.map(&(elem(&1, 0)))
  end

  

  def grid(nodes, d, mod \\ :false) do
    connect_grid(
      add_edges(nodes),
      Enum.reverse(calc_dimensions(length(nodes), d)),
      mod)
  end

  defp get_NbyNcoords(n, d, numNodes) do
    for i <- 1..n do
	    for j <- 1..d, do: {((i-1)*numNodes + j), []}
	  end
  end

  def honeycomb(nodes) do
    side = ceil(:math.sqrt(length(nodes)))
    side = if rem(side, 2) == 0, do: side + 1, else: side

    adjacencyList = honeycombUtil(side * side)
    Enum.map(adjacencyList, fn {node, list} -> 
        {
        case Enum.fetch(nodes, node-1) do
        {:ok, pid} -> pid
        _ -> nil
        end,
        Enum.reduce(list, [], fn item, acc -> 
          case Enum.fetch(nodes, item-1) do
          {:ok, pidNeighbor} -> [pidNeighbor] ++ acc
          _ -> acc
          end
        end)
        }
      end)
      |> Enum.filter(fn {pid, _} -> pid != nil end)
  end

  def randhoneycomb(nodes) do
    side = ceil(:math.sqrt(length(nodes)))
    side = if rem(side, 2) == 0, do: side + 1, else: side

    adjacencyList = 
    honeycombUtil(side * side) |>
    Enum.map(fn {x, y} -> {x, [Enum.random(1..length(nodes))] ++ y} end)

    Enum.map(adjacencyList, fn {node, list} -> 
        {
        case Enum.fetch(nodes, node-1) do
        {:ok, pid} -> pid
        _ -> nil
        end,
        Enum.reduce(list, [], fn item, acc -> 
          case Enum.fetch(nodes, item-1) do
          {:ok, pidNeighbor} -> [pidNeighbor] ++ acc
          _ -> acc
          end
        end)
        }
      end)
      |> Enum.filter(fn {pid, _} -> pid != nil end)
  end

  def honeycomb2(nodes) do
    listNodes = nodes 
    |> add_edges()
    |> Enum.zip(1..length(nodes))
    #|> Enum.chunk_every(side)
    
    Enum.map(listNodes, fn {{node, neighbors}, x} -> 
          if (rem(x,2) == 0) do
            ret = Enum.fetch(listNodes, x-1)
            case ret do
              {:ok, {{addNeighbor, _}, _}} -> {{node, [addNeighbor] ++ neighbors}, x}
              _ -> {{node, neighbors}, x}
            end
          else
            ret = Enum.fetch(listNodes, x+1)
            case ret do
              {:ok, {{addNeighbor, _}, _}} -> {{node, [addNeighbor] ++ neighbors}, x}
              _ -> {{node, neighbors}, x}
            end
          end
          ret = Enum.fetch(listNodes, x-5)
          case ret do
            {:ok, {{addNeighbor, _}, _}} -> {{node, [addNeighbor] ++ neighbors}, x}
            _ -> {{node, neighbors}, x}
          end
          ret = Enum.fetch(listNodes, x+5)
          case ret do
            {:ok, {{addNeighbor, _}, _}} -> {{node, [addNeighbor] ++ neighbors}, x}
            _ -> {{node, neighbors}, x}
          end
          
         
         end)
    #|> Enum.unzip()
    #     else 
    #       {x, [(if rem(x, side) > 0, do: x+1),
    #                 (if x+side <= side*side, do: x+side),
    #                 (if x-side > 0, do: x-side)] ++ y}
    #       #{x, y ++ [x+1, x+5, x-5]}
    #     end
    #     end)
    #   end)
    #|> Enum.map(&(elem(&1, 0)))
    # |> Enum.flat_map(fn x -> x end)
    # |> Enum.map(fn {x, y} -> {x, y -- [nil, nil, nil]} end)
    end

  def honeycombUtil(nodes) do
    side = ceil(:math.sqrt(nodes))
    side = if rem(side, 2) == 0, do: side + 1, else: side
    side
    |> get_NbyNcoords(side, side)
    #|> Enum.map(fn row -> connect_line(row, :false) end)
    |> Enum.map(fn row -> 
      Enum.map(row, fn {x, y} -> 
        if (rem(x,2) == 0) do
          {x, [(if x-1 > 0 and rem(x, side) > 1, do: x-1),
                    (if x+side <= side*side, do: x+side),
                    (if x-side > 0, do: x-side)] ++ y}
        else 
          {x, [(if rem(x, side) > 0, do: x+1),
                    (if x+side <= side*side, do: x+side),
                    (if x-side > 0, do: x-side)] ++ y}
          #{x, y ++ [x+1, x+5, x-5]}
        end
        end)
      end)
      |> Enum.flat_map(fn x -> x end)
      |> Enum.map(fn {x, y} -> {x, y -- [nil, nil, nil]} end)
  end

  def randhoneycomb2(nodes) do
    nodes
    |> honeycomb()
    |> Enum.map(fn {x, y} -> {x, [Enum.random(nodes)] ++ y} end)
  end
  
  defp add_edges(nodes), do: Enum.map(nodes, &({&1, []}))
  
  defp remove_edges(nodes), do: Enum.map(nodes, &(elem(&1, 0)))
  
  defp get_2dcoords(n) do
    for _ <- 1..n do
	    for _ <- 1..2, do: :rand.uniform()
	  end
  end

  defp find_nearby(nodes, r) do
    Enum.map_reduce(nodes, tl(nodes), fn {{node, neighbors}, x}, tail ->
	  {{{node,
		 Enum.reduce_while(tail, [], fn {{node2, _}, y}, acc ->
		   diff = hd(y) - hd(x)
		   cond do
		     abs(diff) > r                            -> {:halt, acc}
			 check_dist(diff*diff, tl(x), tl(y), r*r) -> {:cont, [node2] ++ acc}
			 true                                     -> {:cont, acc}
		   end
		 end) ++ neighbors},
		x},
	   Enum.drop(tail, 1)}
	end)
	  |> elem(0)
  end
  
  defp check_dist(_, [], [], _), do: :true
  
  defp check_dist(d, x, y, r) do
    d2 = d + :math.pow(hd(y)-hd(x), 2)
    if d2 > r, do: :false, else: check_dist(d2, tl(x), tl(y), r)
  end
  
  defp calc_dimensions(_n, d) when d < 1, do: []
  
  defp calc_dimensions(n, d) do
    x = trunc(Float.ceil(:math.pow(n, 1/d)))
	[x] ++ calc_dimensions(n/x, d-1)
  end
  
  defp connect_grid(space, dims, _mod) when length(dims) == 0, do: space
  
  defp connect_grid(space, dims, mod) do
    space
	  |> Enum.chunk_every(hd(dims))
	  |> Enum.map(&(connect_line(&1, mod)))
	  |> list_pivot()
	  |> Enum.flat_map(&(connect_grid(&1, tl(dims), mod)))
  end
  
  defp connect_line(nodes, _mod) when length(nodes) < 2, do: nodes
  
  defp connect_line(nodes, _mod) when length(nodes) == 2 do
    [{node1, nbrs1}, {node2, nbrs2}] = nodes
	[{node1, [node2] ++ nbrs1}, {node2, [node1] ++ nbrs2}]
  end
  
  defp connect_line(nodes, mod) do
    nodes
    |> Enum.map_reduce(
      (if mod do
        {[elem(List.last(nodes), 0)], remove_edges(tl(nodes) ++ [hd(nodes)])}
        else
        {[], remove_edges(tl(nodes))}
        end),
      fn {node, neighbors}, {left, tail} ->
        {{node, left ++ Enum.take(tail, 1) ++ neighbors}, 
        {[node], Enum.drop(tail, 1)}}
      end)
	  |> elem(0)
  end
  
  defp list_pivot(lists) do
    lists
      |> Enum.reduce(List.duplicate([], length(hd(lists))), fn list, zipper ->
	       Enum.map_reduce(zipper, list, &({&1 ++ Enum.take(&2, 1), Enum.drop(&2, 1)}))
		  |> elem(0)
		 end)
  end

  def test do
    #IO.inspect honey([{1, []}, {2, []}, {3, []}, {4, []}], :false)
    #IO.inspect rand2d([1, 2, 3, 4, 5], 2, 0.5)
    #IO.inspect connect_line([{1, []}, {2, []}, {3, []}, {4, []}], :false)
    #IO.inspect honeycomb([1,2,3,4,5])
    # IO.inspect full([1,2,3,4,5])
    # IO.inspect grid([1,2,3,4,5], 1)
    #IO.inspect Enum.chunk_every([1,2,3,4,5,6,1], 2)
    IO.inspect connect_grid([{1,[]},{2,[]},{3,[]},{4,[]},{5,[]},{6,[]},{7,[]},{8,[]}], calc_dimensions(8, 3), :false)
  end
end

Proj2.Topology.test()
