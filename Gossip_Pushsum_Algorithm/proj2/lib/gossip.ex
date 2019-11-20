defmodule Gossip do
  # This is the main module

  def main(args) do
    main_pid = self()
    #obtaining argument list
    argument_list = args

    if length(argument_list) != 3 do
      IO.inspect("Incorrect args; Enter no. of nodes topology and alogorithm")
      Process.exit(main_pid,reason: :normal)
    end

    num_nodes = String.to_integer(Enum.at(argument_list, 0))
    topology = Enum.at(argument_list, 1)
    algorithm = Enum.at(argument_list, 2)

    if num_nodes <= 1 do
      IO.puts("Nodes should be greater than 1")
      Process.exit(main_pid,reason: :normal)
    end

    # add correction:based on topology, if necessary rounding up to the next best value
    num_nodes = Utils.node_correction(num_nodes, topology)

    node_list =
      Enum.map(0..num_nodes - 1, fn n ->
        actor = "actor_" <> to_string(n)
        String.to_atom(actor)
      end)

    if algorithm == "gossip" do
      # Starting the watcher here
      {:ok, watcher_pid} = GenServer.start_link(Watcher, [main_pid, length(node_list), topology])
      spawn_actors(node_list, main_pid, watcher_pid)

      #map each node to its list of neighbors
      map_of_neighbors = Utils.get_neighbors(node_list, topology)
      #IO.inspect(map_of_neighbors)

      #now set appropriate list of neighbors to each actor
      for {actor_name, neighbors} <- map_of_neighbors do
        # GossipActor.set_neighbors(actor, neighbors)
        GenServer.cast(actor_name, {:set_neighbors, neighbors})
      end

      #record start time
      start_time = :os.system_time(:millisecond)

      #start gossip protocol
      start_gossiping(node_list)

      # Watcher calls the end, when all the actors are done
      receive do
        {:algo_end, _response} ->
          end_time = :os.system_time(:millisecond)
          IO.puts("Time taken for convergence is #{end_time - start_time}ms")
      end

    else
      # Pushsum logic starts here
      if algorithm == "pushsum" do
        #Start the watcher GenServer. This keeps track of all the actors that have reached the protocol
        #termination condition
        {:ok, watcher_pid} = GenServer.start_link(Watcher, [main_pid, length(node_list), topology])
        spawn_pushsum_actors(node_list, watcher_pid)
        #receive a map pf neighbors
        map_of_neighbors = Utils.get_neighbors(node_list, topology)
        #IO.inspect(map_of_neighbors)
        # now set appropriate list of neighbors to each actor
        for {actor_name, neighbors} <- map_of_neighbors do
          GenServer.cast(actor_name, {:set_neighbors, neighbors})
        end
        #record start time
        start_time = :os.system_time(:millisecond)

        #start protocol
        start_pushsum(node_list)

        receive do
          {:algo_end, _response} ->
            end_time = :os.system_time(:millisecond)
            IO.puts("Time taken for convergence is #{end_time - start_time}ms")
        end
      else
        IO.puts("Invalid algorithm, please enter a valid algorithm")
      end
    end
  end

  def spawn_actors(node_list, main_pid, watcher_pid) do
    Enum.map(node_list, fn n ->
      {:ok, actor} = GenServer.start_link(GossipActor, ["", n, main_pid, watcher_pid], name: n)
      actor
    end)
  end

  def start_gossiping(node_list) do
    #pick a random actor and start gossip
    actor_name = Enum.random(node_list)
    GenServer.cast(actor_name, {:receive_rumor, "rumor", actor_name})
  end


  def spawn_pushsum_actors(node_list, watcher_pid) do
    Enum.map(node_list, fn n ->
      [_, actorNumber] = String.split(Atom.to_string(n), "_")
      s_integer = String.to_integer(actorNumber)
      {:ok, actor} = GenServer.start_link(PushsumActor, [s_integer, 0, n, watcher_pid], name: n)
      actor
    end)
  end

  def start_pushsum(node_list) do
    #pick random actor and start Push-Sum
    actor_name = Enum.random(node_list)
    GenServer.cast(actor_name, {:transmit_values})

  end

end
