defmodule Utils do
  # def nextHop(n,g,self,rt) do
  #   if n == length(rt) do
  #     self
  #   else
  #     d = Enum.at(String.codepoints(g), n)
  #     e = rt[n][d]
  #     while
  #
  #      e == nil do
  #       d = d + 1
  #       e = rt[n][d]
  #     end
  #     if e == self do
  #       nextHop(n + 1,g,self,rt)
  #     else
  #       e
  #     end
  #   end
  # end
  #
  # def tableInit(n) do
  #   Enum.reduce(0..n, %{}, fn x, acc ->
  #     Map.put(acc, x, Enum.reduce(0..15, %{}, fn y, acc1 ->
  #       Map.put(acc1,Integer.to_string(y, 16),nil)
  #   end))
  #   end)
  # end



#Generates the routing table
  def tableInit(n,node_id,node_list) do
    IO.puts "node is #{node_id}"
    Enum.reduce(0..n, %{}, fn x, acc ->
      Map.put(acc, x, Enum.reduce(0..15, %{}, fn y, acc1 ->
        Map.put(acc1,Integer.to_string(y, 16),get_entry_node(node_id,node_list,x,Integer.to_string(y, 16)))
      end))
    end)
  end

#Gets the node that is to be added to the routing table
  def get_entry_node(node_id,node_list,level,column) do
    # IO.puts "level is #{level}"
    # IO.puts "column is #{column}"
    if(level==0 and column==0) do
      nil
    else
      if(level==0) do
          possible_entries_list = Enum.filter(node_list, fn node->
          if(String.at(node,level) == column) do
            node
          else
            nil
          end
          # See if we can add a code that removes whatever was supposed to go in
        end)
        # IO.puts "Possible nodes list is"
        # IO.inspect possible_entries_list
        closest_node = calculate_closest(possible_entries_list, node_id)
        # IO.puts "Closest node for #{column} is #{closest_node}"
      else
        possible_entries_list = Enum.filter(node_list, fn node->
          longest_matching_length=longest_prefix_match(node,node_id, 0,0)
          if(longest_matching_length >= level) do
            if(String.at(node,level) == column) do
              node
            else
              nil
            end
          end
        end)
        # IO.puts "Possible nodes list is"
        # IO.inspect possible_entries_list
        closest_node = calculate_closest(possible_entries_list, node_id)
      end
    end
  end

#Returns the length to which prefix is matching with the given node
  def longest_prefix_match(key,hash_id,start_value,longest_prefix_count) do
    # IO.puts "Node id is #{hash_id} #{key} #{start_value} #{longest_prefix_count}"

   longest_prefix_count=cond do
       (String.at(key,start_value) == String.at(hash_id,start_value)) &&  longest_prefix_count<=String.length(hash_id)->
           longest_prefix_match(key,hash_id,start_value+1,longest_prefix_count+1)
       true ->
           longest_prefix_count
   end
   longest_prefix_count
 end

 def calculate_closest([], _), do: nil

  def calculate_closest(entries_list, node_id) do
    node_integer_value = String.to_integer(node_id,16)

    distance_list = Enum.map(entries_list, fn entry->
      # IO.puts "Entry is #{entry}"
        enrty_integer_value = String.to_integer(entry,16)
        abs(node_integer_value-enrty_integer_value)
    end)
    # IO.puts "Distance list is"
    # IO.inspect distance_list
      min = Enum.min(distance_list)
      index = Enum.find_index(distance_list,fn x-> x==min end)
      Enum.at(entries_list,index)
  end

end
