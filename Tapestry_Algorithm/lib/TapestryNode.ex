defmodule TapestryNode do
  use GenServer

  def init(node_state) do

    state=  %{
      "main_pid" => Enum.at(node_state, 0),
      "routingTable" => Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),Enum.at(node_state, 1)),
      "nodeID" => Enum.at(node_state, 2),
      "Global_list" => Enum.at(node_state, 1),
      "backPointers" => []
      }
    # IO.inspect state["routingTable"]
    {:ok, state}
  end

  # def handle_cast(:addNode, n) do
  #
  # end

  n = :rand.uniform(10000)
  object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))



end
