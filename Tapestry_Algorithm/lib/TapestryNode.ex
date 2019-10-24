defmodule TapestryNode do
  use GenServer

  def init(node_state) do

    state=  %{
      "main_pid" => Enum.at(node_state, 0),
      "routingTable" => Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),Enum.at(node_state, 1)),
      "nodeId" => Enum.at(node_state, 2),
      "Global_list" => Enum.at(node_state, 1),
      "backPointers" => []
      }
    #IO.inspect state["routingTable"]
    {:ok, state}
  end

  # def handle_cast(:addNode, n) do
  #
  # end
  #n = :rand.uniform(10000)
  #object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))

  def handle_cast({:findSurrogate, n, newNodeId},state) do
    next = Utils.nextHop(n,newNodeId,state["nodeId"],state["routingTable"])
    nextHop = next["node"]
    curLevel = Utils.longest_prefix_match(newNodeId,state["nodeId"], 0,0)
    isRootNode = if state["nodeId"] == nextHop do
      true
    else
      false
    end
    if isRootNode do
      #check prefix match length to multicast
      #here curLevel gives us the prefix match length
      #multicast to the nodes in that level
      Enum.each(state["routingTable"][curLevel], fn x -> if x != nil do
        GenServer.cast(x, {:addNodeMulticast, n, newNodeId}) end
        end)

      column = String.at(newNodeId,curLevel)
      state = if state["routingTable"][curLevel][column] == nil do
        state = put_in(state, ["routingTable",curLevel,column], newNodeId)
        #notifying new node that current node updated its routing table
        #GenServer.cast(newNodeId {:updateBackPointers, state["nodeId"], curLevel)
        state
      else
        newDistance = abs(String.to_integer(newNodeId, 16) - String.to_integer(state["nodeId"], 16))
        curDistance = abs(String.to_integer(newNodeId, 16) - String.to_integer(state["routingTable"][curLevel][column], 16))
        if newDistance < curDistance do
          state = put_in(state, ["routingTable",curLevel,column], newNodeId)
          #notifying new node that current node updated its routing table
          #GenServer.cast(newNodeId, {:updateBackPointers, state["nodeId"], curLevel})
          state
        end
      end

    else
      #go to the next hop to find the right surrogate
      GenServer.cast(nextHop, {:findSurrogate, curLevel + 1, newNodeId})
    end
    state
  end

  #def handle_cast({:addNodeMulticast, n, newNodeId}, state) do

  #end


end
