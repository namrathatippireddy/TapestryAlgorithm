defmodule TapestryNode do
  use GenServer

  def init(node_state) do

    state=  %{
      "main_pid" => Enum.at(node_state, 0),
#      "routingTable" => Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),Enum.at(node_state, 1)),
      "routingTable" => Utils.tableInit(Enum.at(node_state,4),node_state),
      "nodeId" => Enum.at(node_state, 2),
      "global_list" => Enum.at(node_state, 1),
      "backPointers" => [],
      "node_hash_length" => Enum.at(node_state, 3)
      }
    #IO.inspect(state["routingTable"])
    IO.inspect(state["nodeId"])
    IO.inspect(state["node_hash_length"])
    {:ok, state}
  end

  # def handle_cast(:addNode, n) do
  #
  # end
  #n = :rand.uniform(10000)
  #object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
  '''
  def tableInit(isDynamic,node_state) do
    if isDynamic == true do
      Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),Enum.at(node_state, 1))
    else
      firstNode = Enum.at(Enum.at(node_state,1),0)
      newList = GenServer.call(firstNode, {:findSurrogate, 0, Enum.at(node_state, 2)}, 500000)
      Utils.tableInit(Enum.at(node_state, 3),Enum.at(node_state, 2),newList)
    end
  end
  '''

  def handle_cast({:start_hop, num_msgs}, state) do
    #IO.puts "Inside start hop"
    string_length = state["node_hash_length"]
    IO.inspect string_length
    Enum.each(1..num_msgs, fn _x ->
     n = :rand.uniform(10000)
     object_hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
     object_hash_nozero = remove_zero(object_hash)
     IO.inspect state
     len = String.length(state["nodeId"])
     final_object_hash = String.slice((object_hash_nozero),0..len)
    #IO.puts "Final object hash is #{final_object_hash}"
    GenServer.cast(self, {:next_hop, 0, 0, final_object_hash})
    end)
    {:noreply, state}

  end

  def handle_cast({:next_hop, hopCount, level, objectId}, state) do
    self = state["nodeId"]
    rt = state["routingTable"]
    next_hop=Utils.nextHop(level,objectId,self,rt)
    #IO.inspect("#{next_hop["level"]} #{next_hop["node"]} #{objectId}")
    if next_hop["node"] == self do
      #this means that self is the root node for objectId
      #send hop count to main
      send(state["main_pid"], {:hop_count,hopCount})
    else
      #self is not root. got next hop node
      #increment hopcount and cast to next hop node
      #IO.inspect("to next hope #{next_hop["node"]}")
      GenServer.cast(String.to_atom("actor_"<>next_hop["node"]), {:next_hop, hopCount + 1, next_hop["level"], objectId})
    end
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

  def handle_call({:findSurrogate, n, newNodeId},_from,state) do

    self = state["nodeId"]
    next = Utils.nextHop(n,newNodeId,state["nodeId"],state["routingTable"])
    nextHop = next["node"]
    curLevel = Utils.longest_prefix_match(newNodeId,state["nodeId"], 0,0)
    IO.inspect("next hop is #{nextHop}")
    isRootNode = if state["nodeId"] == nextHop do
      true
    else
      false
    end

    newNodeList = if isRootNode do
      IO.inspect("rootNode is true")
      #check prefix match length to multicast
      #here curLevel gives us the prefix match length
      #multicast to the nodes in that level
      #GenServer.call(String.to_atom("actor_"<>self), {:addNodeMulticast, curLevel, newNodeId}, 200000)
      curNodes =  Enum.reduce(state["routingTable"][n], [],fn {_y,x}, acc ->
        if x != nil do
          acc ++ [x]
        else
          acc
        end
      end)
      #multicast to current Level
      node_list = Enum.reduce(curNodes, curNodes, fn x, acc ->
        if x != state["nodeId"] do
          lowerNodeList = GenServer.call(String.to_atom("actor_"<>x), {:addNodeMulticast, curLevel + 1, newNodeId}, 120000)
          acc ++ lowerNodeList
        else
          acc
        end
      end)

    else
      IO.inspect("rootNode is false")
      curNodes =  Enum.reduce(state["routingTable"][n], [],fn {_y,x}, acc ->
        if x != nil do
          acc ++ [x]
        else
          acc
        end
      end)
      #go to the next hop to find the right surrogate
      curNodes ++ GenServer.call(String.to_atom("actor_"<>nextHop), {:findSurrogate, next["level"], newNodeId}, 300000)
    end
    #add node to own routing table at curLevel
    column = String.at(newNodeId,curLevel)
    state = if state["routingTable"][curLevel][column] == nil do
        state = put_in(state, ["routingTable",curLevel,column], newNodeId)
        #notifying new node that current node updated its routing table
        #GenServer.cast(newNodeId {:updateBackPointers, state["nodeId"], curLevel)
        state
      else
        newDistance = abs(String.to_integer(newNodeId, 16) - String.to_integer(state["nodeId"], 16))
        curDistance = abs(String.to_integer(state["routingTable"][curLevel][column], 16) -
                  String.to_integer(state["nodeId"], 16))
        state = if newDistance < curDistance do
          state = put_in(state, ["routingTable",curLevel,column], newNodeId)
          #notifying new node that current node updated its routing table
          #GenServer.cast(newNodeId, {:updateBackPointers, state["nodeId"], curLevel})
          state
        end
          state
    end
    IO.inspect("returning")
    #IO.inspect newNodeList
    #IO.inspect state
    {:reply, newNodeList,state}
  end

  def handle_call({:addNodeMulticast, curLevel, newNodeId}, _from,state) do
    #multicast to current Level
    curNodes = Enum.reduce(state["routingTable"][curLevel], [],fn {_y,x}, acc ->
      if x != nil do
        acc ++ [x]
      else
        acc
      end
    end)
    node_list = Enum.reduce(curNodes, curNodes, fn x, acc ->
        if x != state["nodeId"] do
          lowerNodeList = GenServer.call(String.to_atom("actor_"<>x), {:addNodeMulticast, curLevel + 1, newNodeId}, 120000)
          acc ++ lowerNodeList
        else
          acc
        end
      end)

    #add node to own routing table at curLevel
    column = String.at(newNodeId,curLevel)
    IO.inspect state
    state = if state["routingTable"][curLevel][column] == nil do
      state = put_in(state, ["routingTable",curLevel,column], newNodeId)
      #notifying new node that current node updated its routing table
      #GenServer.cast(newNodeId {:updateBackPointers, state["nodeId"], curLevel)
      state
      else
      newDistance = abs(String.to_integer(newNodeId, 16) - String.to_integer(state["nodeId"], 16))
      curDistance = abs(String.to_integer(state["routingTable"][curLevel][column], 16) -
                   String.to_integer(state["nodeId"], 16))
      state = if newDistance < curDistance do
          state = put_in(state, ["routingTable",curLevel,column], newNodeId)
          #notifying new node that current node updated its routing table
          #GenServer.cast(newNodeId, {:updateBackPointers, state["nodeId"], curLevel})
          state
        else
          state
        end
    end
    IO.inspect state
    {:reply, node_list,state}
  end
end
