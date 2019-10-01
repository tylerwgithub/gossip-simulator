defmodule Proj2.Topology do
  @moduledoc """
  Documentation for Proj2.Topology

  The functions in this module define various network topologies.
  Each function takes a list of nodes as input, and outputs a list of tuples in the form {node, neighbors}.
  """

  @doc """
  Defines a fully-connected network, where each node is a neighbor of every other node.
  """
  #TY
  def full(nodes) do
    # IO.inspect nodes
    nodes |> Enum.map(fn x -> {x, nodes -- [x]} end)
    # topo = nodes
	  # |> Enum.map_reduce({[], tl(nodes)}, fn node, {head, tail} -> {{node, head ++ tail}, {[node] ++ head, Enum.drop(tail, 1)}} end)
	  # |> elem(0)
    # IO.inspect
  end


  @doc """
  Defines a randomized 2D proximity network, where neighbors are nodes within the defined radius.
  
  ## Parameters
    - d:    Number of dimensions in the network space.
    - r:    Proximity radius to use for determining neighbors, must be less than 1.
    - dist: Distribution to use when assigning coordinates to nodes. Possible values:
              - uniform: Uniform random distribution (default).
              - equal:   Equidistant (non-random) distribution.
  """
  def proximity(nodes, dimension, radius) do
    nodes
	  |> add_neighbors()
	  |> Enum.zip(get_coords(length(nodes), dimension))
	  |> Enum.sort(&(hd(elem(&1, 1)) <= hd(elem(&2, 1))))
	  |> find_nearby(radius)
	  |> Enum.reverse()
	  |> find_nearby(radius)
	  |> Enum.map(&(elem(&1, 0)))
  end

  @doc """
  Defines an orthogonal grid network in d dimensions.
  The dimensional root of the number of nodes need not be an integer, although this may create a strange topology when using circular dimensions.
  
  ## Parameters
    - d:    Dimensionality of the grid. For example d = 1 creates a line, d = 3 creates a cube, and d > 3 creates a hypercube.
    - mod:  Flag to indicate if dimensions are circular i.e. they wrap around. Defaults to :false.
    - rand: Flag to indicate if random pairwise connections should be added to the grid. Defaults to :false.
  """
  def grid(nodes, d, mod \\ :false, rand \\ :false) do
	randomize(
	  connect_grid(
	    add_neighbors(nodes),
	    Enum.reverse(calc_dimensions(length(nodes), d)),
	    mod),
	  rand)
  end

  defp get_NbyNcoords(n, d, numNodes) do
    for i <- 1..n do
	    for j <- 1..d, do: {((i-1)*numNodes + j), []}
	  end
  end

  def honeycomb(nodes) do
    side = round(:math.sqrt(nodes))
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

  def randhoneycomb(nodes) do
    nodes
    |> honeycomb()
    |> Enum.map(fn {x, y} -> {x, [:rand.uniform(nodes)] ++ y} end)
  end
  ## Helper functions
  
  defp add_neighbors(nodes), do: Enum.map(nodes, &({&1, []}))
  
  defp strip_neighbors(nodes), do: Enum.map(nodes, &(elem(&1, 0)))
  
  defp get_coords(n, d) do
    for _ <- 1..n do
	    for _ <- 1..d, do: :rand.uniform()
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
        {[elem(List.last(nodes), 0)], strip_neighbors(tl(nodes) ++ [hd(nodes)])}
        else
        {[], strip_neighbors(tl(nodes))}
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
  
  defp randomize(nodes, rand) when rand do
    nodes
	  |> Enum.shuffle()
	  |> pair_up([])
  end
  
  defp randomize(nodes, _rand), do: nodes
  
  defp pair_up(nodes, pairs) when length(nodes) < 2, do: pairs ++ nodes
  
  defp pair_up(nodes, pairs) when length(nodes) == 2 do
    if elem(Enum.at(nodes, 1), 0) in elem(Enum.at(nodes, 0), 1) do
	  pairs ++ nodes
	else
	  pair_up(Enum.drop(nodes, 2), connect_line(Enum.take(nodes, 2), nil) ++ pairs)
	end
  end
  
  defp pair_up(nodes, pairs) do
	if elem(Enum.at(nodes, 1), 0) in elem(Enum.at(nodes, 0), 1) do
	    pair_up(Enum.shuffle(nodes), pairs)
	else
	    pair_up(Enum.drop(nodes, 2), connect_line(Enum.take(nodes, 2), nil) ++ pairs)
	end
  end

  def test do
    #IO.inspect honey([{1, []}, {2, []}, {3, []}, {4, []}], :false)
    IO.inspect proximity([1, 2, 3, 4, 5], 2, 0.5)
    #IO.inspect connect_line([{1, []}, {2, []}, {3, []}, {4, []}], :false)
    #IO.inspect honey([1,2,3,4,5], :false)
  end

end

Proj2.Topology.test()
