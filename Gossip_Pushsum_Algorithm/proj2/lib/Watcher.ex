# ToDo: implement all correct
defmodule Watcher do
  use GenServer

  def init(watcher_state) do
    {:ok,
     %{
       "main_pid" => Enum.at(watcher_state, 0),
       "num_nodes" => Enum.at(watcher_state, 1),
       "death_count" => 0,
       "topology" => Enum.at(watcher_state, 2)
     }}
  end

  def handle_cast({:increment_deaths}, state) do
    {:ok, num_nodes} = Map.fetch(state, "num_nodes")
    {:ok, death_count} = Map.fetch(state, "death_count")
    {:ok, main_pid} = Map.fetch(state, "main_pid")

    {:ok, topology} = Map.fetch(state, "topology")
    top_sparse = %{"line" => 70, "full" => 70, "honeycomb" => 60, "rand2D" => 70, "3Dtorus" => 70, "randhoneycomb" => 70}

    if (death_count/num_nodes)*100 > top_sparse[topology] do
      send(main_pid, {:algo_end, ""})
    end

    state = Map.put(state, "death_count", death_count + 1)

    {:noreply, state}
  end

  def handle_cast({:algo_end}, state) do
    {:ok, main_pid} = Map.fetch(state, "main_pid")
    send(main_pid, {:algo_end, ""})
  end

end
