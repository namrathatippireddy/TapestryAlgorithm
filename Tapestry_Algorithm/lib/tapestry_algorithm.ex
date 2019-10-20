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
    num_requests = Enum.at(arguments, 1)

    node_ids_list = generate_node_ids(num_nodes)
    node_ids_integers = convert_node_ids_to_integers(node_ids_list)

end

def generate_node_ids(num_nodes) do
  node_list = Enum.map(1..num_nodes, fn node ->
    Base.encode16(:crypto.hash(:sha, "#{node}"))
  end)
  #IO.inspect node_list
  node_list
end

def convert_node_ids_to_integers(node_ids_list) do
  node_id_inInteger = Enum.map(node_ids_list, fn node ->
    String.to_integer(node,16)
  end)
  IO.inspect node_id_inInteger
  node_id_inInteger
end


end
