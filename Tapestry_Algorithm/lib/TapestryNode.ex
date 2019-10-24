defmodule TapestryNode do
  use GenServer

  def init(node_state) do

    state=  %{
      "main_pid" => Enum.at(node_state, 0),
      "routingTable" => Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),Enum.at(node_state, 1)),
      "nodeID" => Enum.at(node_state, 2),
      "global_list" => Enum.at(node_state, 1),
      "backPointers" => [],
      "node_hash_length" => Enum.at(node_state, 3)
      }
    # IO.inspect state["routingTable"]
    {:ok, state}
  end

  # def handle_cast(:addNode, n) do
  #
  # end
  #n = :rand.uniform(10000)
  #object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))


  def handle_cast({:start_hop, hopcount, level}, state) do
    IO.puts "Inside start hop"
    string_length = state["node_hash_length"]
    n = :rand.uniform(10000)
    object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
    object_hash_nozero = remove_zero(object_hash)
    final_object_hash=String.slice((object_hash_nozero),0..string_length)
    IO.puts "Final object hash is #{final_object_hash}"
    self = state["nodeID"]
    rt = state["routingTable"]

    next_hop=Utils.nextHop(level,final_object_hash,self,rt)
    IO.inspect("#{next_hop["level"]} #{next_hop["node"]} #{final_object_hash}")

  {:noreply, state}
  end

  #This removes the nodes with leading zeros
    def remove_zero(object_hash) do
      object_hash_nozero=cond do
           (String.at(object_hash, 0)=="0") ->
             # IO.puts "Node hash is #{node_hash}"
              n = :rand.uniform(10000)
              hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
              remove_zero(hash)
           true ->
               object_hash
      end
       object_hash_nozero
    end

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
      Enum.each(state["routingTable"][curLevel], fn {_y,x} ->
        if x != nil do
          GenServer.cast(x, {:addNodeMulticast, n, newNodeId})
        end
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
    {:noreply, state}
  end

  #def handle_cast({:addNodeMulticast, n, newNodeId}, state) do

  #end


end
