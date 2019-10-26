defmodule TapestryAlgorithm do
  #this is the main module
  def main() do
    main_pid = self()
    arguments = System.argv()

    if length(arguments)!=2 do
      IO.puts "Enter the number of nodes and number of requests to be made"
      Process.exit(main_pid,reason: :normal)
    end

    num_nodes = String.to_integer((Enum.at(arguments, 0)))
    num_requests = String.to_integer((Enum.at(arguments, 1)))
    total_msgs = num_nodes * num_requests

    add_value = (num_nodes*num_requests)
    string_length=String.length(Integer.to_string(add_value))
    # IO.puts "Length is #{string_length}"

    node_ids_list = generate_node_ids(num_nodes, string_length)
    Enum.each(node_ids_list, fn node->
      # routing_table = tableInit(string_length,node,node_ids_list)
      {:ok, _tapestry_node_pid} = GenServer.start_link(TapestryNode,
           [main_pid, node_ids_list, node, string_length], name: String.to_atom("actor_"<>node))
      #IO.inspect tapestry_node_pid
    end)

    #Start requesting for objects
    start_requesting(node_ids_list, num_requests)
    maxCount = 0
    responseCount = 0
    loop(0,0,total_msgs - num_requests)
  end

  def loop(maxCount, responseCount, total_msgs) do
    receive do
      {:hop_count, count} ->
        #IO.inspect("count is #{count}")
        maxCount = if maxCount < count do
          count
        else
          maxCount
        end
        responseCount = responseCount + 1
        if total_msgs != responseCount do
          loop(maxCount,responseCount,total_msgs)
        else
          IO.inspect "Max count value is #{maxCount}"
        end
    end
  end

  def start_requesting(node_ids_list, num_requests) do
    Enum.each(node_ids_list, fn node->
      GenServer.cast(String.to_atom("actor_"<>node), {:start_hop, num_requests})
    end)
  end

  #This is generating the node ids
  def generate_node_ids(num_nodes, string_length) do
    node_list = Enum.reduce(1..num_nodes-1, [],fn node, acc->
      node_hash = Base.encode16(:crypto.hash(:sha, "#{node}"))
      # if(String.at(node_hash, 0)==0) do
      # longest_prefix_count=cond do
      node_hash_sliced = remove_zero_or_duplicates(node_hash, acc, string_length)

      acc = acc ++ [node_hash_sliced]
      #IO.inspect acc
      # Base.encode16(:crypto.hash(:sha, "#{node}"))
    end)
    IO.inspect node_list
    node_list
  end

#This removes the nodes with leading zeros
  def remove_zero_or_duplicates(node_hash, acc, string_length) do
    node_hash_sliced = String.slice((node_hash),0..string_length)
    #IO.inspect is_list(acc)
    #IO.inspect acc
    node_hash_nozero=cond do
         (String.at(node_hash, 0)=="0") or Enum.member?(acc, node_hash_sliced) ->
            n = :rand.uniform(10000)
            hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
            remove_zero_or_duplicates(hash,acc,string_length)
         true ->
            node_hash_sliced
    end
     node_hash_nozero
  end



end
