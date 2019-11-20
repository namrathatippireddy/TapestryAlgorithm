defmodule GossipActor do
  use GenServer

  def init(gossip_state) do
    {:ok,
     %{
       "message" => Enum.at(gossip_state, 0),
       "count" => 0,
       "neighbors" => [],
       "name" => Enum.at(gossip_state, 1),
       "main_pid" => Enum.at(gossip_state, 2),
       "watcher_pid" => Enum.at(gossip_state, 3)
     }}
  end

  def handle_cast({:set_neighbors, neighbors}, state) do
    # IO.inspect(neighbors)
    {:noreply, Map.put(state, "neighbors", neighbors)}
  end

  def handle_cast({:transmit_rumor, rumor}, state) do
    state = Map.put(state, "message", rumor)

    {:ok, message} = Map.fetch(state, "message")
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    {:ok, count} = Map.fetch(state, "count")
    {:ok, actor_name} = Map.fetch(state, "name")

    if length(neighbors) != 0 && count <= 10 do
      _ = GenServer.cast(Enum.random(neighbors), {:receive_rumor, message, actor_name})
    end

    # add sleep
    Process.sleep(10)
    GenServer.cast(actor_name, {:transmit_rumor, message})
    {:noreply, state}
  end

  def handle_cast({:receive_rumor, rumor, _sender}, state) do
    {:ok, count} = Map.fetch(state, "count")
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    {:ok, actor_name} = Map.fetch(state, "name")
    {:ok, watcher_pid} = Map.fetch(state, "watcher_pid")

    if count > 10 do
      #If count > 10 ask neighbor nodes to remove this genServer from their neighbor list
      Enum.each(neighbors, fn each_neighbor ->
        _ = GenServer.cast(each_neighbor, {:terminate_neighbor, actor_name})
      end)

      #  Watcher-ToDo: Make a call to the increse watcher count of Implement watcher
      # The cast call might be wrong and I need to pass the pid of watcher here
      GenServer.cast(watcher_pid, {:increment_deaths})
      {:noreply, state}

    else
      {:ok, actor_name} = Map.fetch(state, "name")
      state = Map.put(state, "count", count + 1)
      # IO.puts("count value is #{count}")
      {:ok, existing_msg} = Map.fetch(state, "message")

      if(existing_msg == "") do
        state = Map.put(state, "message", rumor)
        GenServer.cast(actor_name, {:transmit_rumor, existing_msg})
        {:noreply, state}
      else
        # IO.inspect("here #{count + 1}")
        {:noreply, state}
      end
    end
  end

  def handle_cast({:terminate_neighbor, neighbor}, state) do
    # IO.inspect("removing #{neighbor}")
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    # because of self() and the name conflict, it messes up here
    Map.put(state, "neighbors", List.delete(neighbors, neighbor))
    # IO.inspect("new state #{state}")
    {:noreply, state}
  end

end
