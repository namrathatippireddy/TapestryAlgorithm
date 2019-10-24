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

    add_value = (num_nodes*num_requests)
    string_length=String.length(Integer.to_string(add_value))
    # IO.puts "Length is #{string_length}"

    node_ids_list = generate_node_ids(num_nodes, string_length)
    Enum.each(node_ids_list, fn node->
      # routing_table = tableInit(string_length,node,node_ids_list)
      {:ok, tapestry_node_pid} = GenServer.start_link(TapestryNode, [main_pid, node_ids_list, node, string_length], name: String.to_atom("actor_"<>node))
      # IO.inspect tapestry_node_pid
    end)

    #Start requesting for objects
    start_requesting(node_ids_list)

      receive do
        {:algo_end, _response} ->

      end

  end

  def start_requesting(node_ids_list) do
    Enum.each(node_ids_list, fn node->
      IO.puts "Inside start requesting"
      GenServer.cast(String.to_atom("actor_"<>node), {:start_hop, 0, 0})
    end)
  end
  #This is generating the node ids
  def generate_node_ids(num_nodes, string_length) do
    node_list = Enum.map(1..num_nodes-1, fn node ->
      node_hash=Base.encode16(:crypto.hash(:sha, "#{node}"))
      # if(String.at(node_hash, 0)==0) do
      # longest_prefix_count=cond do
      node_hash_nozero = remove_zero(node_hash)
      String.slice((node_hash_nozero),0..string_length)
      # Base.encode16(:crypto.hash(:sha, "#{node}"))
    end)
    IO.inspect node_list
    node_list
  end

#This removes the nodes with leading zeros
  def remove_zero(node_hash) do
    node_hash_nozero=cond do
         (String.at(node_hash, 0)=="0") ->
           # IO.puts "Node hash is #{node_hash}"
            n = :rand.uniform(10000)
            hash = Base.encode16(:crypto.hash(:sha, "#{n}"))
            remove_zero(hash)
         true ->
             node_hash
    end
     node_hash_nozero
  end



end
