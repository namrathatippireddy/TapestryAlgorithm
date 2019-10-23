defmodule TapestryNode do
  use GenServer

  def init(state) do
    {:ok,
      %{
      "routingTable" = Utils.tableInit(length(state["nodeID"])
      "nodeID" = state["nodeID"]
      "backPointers" = []
      }
    }
  end

  def handle_cast(:addNode, n) do

  end

end
