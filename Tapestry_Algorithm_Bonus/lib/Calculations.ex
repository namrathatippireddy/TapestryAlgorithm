defmodule Utils do

  def nextHop(n,g,self,rt) do
    # IO.inspect rt
    if n == map_size(rt) do
      %{"node"=> [self], "level" => n}
    else
      #IO.puts "Inside else part"
      d = String.at(g,n)
      e = rt[n][d]
      e = checkColumn(e,n,d,rt)

      if Enum.at(e,0) == self do
        nextHop(n + 1,g,self,rt)
      else
        %{"node" => e, "level" => n+1}
      end
    end
  end

  def checkColumn(e,n,d,rt) do
    d = String.to_integer(d,16)
    next =  cond do
	    e == [] ->
      d = rem((d + 1),16)
      d = Integer.to_string(d, 16)
      e = rt[n][d]
      if e != [] do
        #IO.inspect e
      end
	    checkColumn(e,n,d,rt)
    true->
      #IO.inspect "here"
      #IO.inspect e
      e
    end
    #IO.inspect("returning  #{next} for #{e} #{n} #{self}")
    IO.inspect next
    next
  end

  #Generates the routing table
  def tableInit(n,node_id,node_list) do
    #IO.puts "node is #{node_id}"
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
        closest_node_list= calculate_closest(possible_entries_list, [],node_id)
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
        closest_node_list = calculate_closest(possible_entries_list, [],node_id)
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

  #def calculate_closest([], _), do: nil

  def calculate_closest(entries_list,closest_node_list,node_id) do
    if length(closest_node_list) == 3 or length(entries_list) == 0 do
      closest_node_list
    else
      node_integer_value = String.to_integer(node_id,16)

      distance_list = Enum.map(entries_list, fn entry->
        # IO.puts "Entry is #{entry}"
          enrty_integer_value = String.to_integer(entry,16)
          abs(node_integer_value-enrty_integer_value)
      end)
      min = Enum.min(distance_list)
      index = Enum.find_index(distance_list,fn x-> x==min end)
      n = Enum.at(entries_list,index)
      new_entries_list = List.delete(entries_list, Enum.at(entries_list,index))
      closest_node_list = closest_node_list ++ [n]
      calculate_closest(new_entries_list,closest_node_list,node_id)
    end
  end
  '''
  def calculate_closest(entries_list, node_id) do
    closest_list =[]
    node_integer_value = String.to_integer(node_id,16)

    distance_list = Enum.map(entries_list, fn entry->
        enrty_integer_value = String.to_integer(entry,16)
        abs(node_integer_value-enrty_integer_value)
    end)
    # IO.puts "Distance list is"
    # IO.inspect distance_list
      min = Enum.min(distance_list)
      index = Enum.find_index(distance_list,fn x-> x==min end)
      n=Enum.at(entries_list,index)
      List.delete(entries_list, Enum.at(entries_list,index))
      n
  end
  '''
end
