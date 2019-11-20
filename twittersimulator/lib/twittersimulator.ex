defmodule TwitterSimulator do
  def main() do
    simulator_pid = self()
    arguments = System.argv()

    if length(arguments) != 2 do
      IO.puts("Enter the number of users to simulate and number of tweets each user has to make")
      Process.exit(simulator_pid, reason: :normal)
    end

    number_of_users = String.to_integer(Enum.at(arguments, 0))
    number_of_tweets = String.to_integer(Enum.at(arguments, 1))

    # Start the engine
    IO.puts("Starting engine")
    {:ok, engine_name} = GenServer.start_link(Engine, [], name: String.to_atom("engine_" <> "1"))

    start_simulating(number_of_users, engine_name)
  end

  def start_simulating(number_of_users, engine_name) do
    # First create users i.e start clients
    # IO.puts "Number of users is #{number_of_users}"
    create_users(number_of_users, engine_name)
  end

  def create_users(num_users, engine_name) do
    # IO.puts "Number of users is #{num_users}"

    Enum.each(1..num_users, fn user ->
      {:ok, _user} =
        GenServer.start_link(Client, [engine_name], name: String.to_atom(Integer.to_string(user)))
      IO.puts("registering created users")
      GenServer.cast(String.to_atom(to_string(user)),{:register, user})
      IO.puts("Asking users to subscribe ")
      GenServer.cast(String.to_atom(to_string(user)),{:subscribe, user, num_users})
      #Make each user do one random action
      # action_list = [1,2,3,4]
      action_list = [1]
      action = Enum.random(action_list)
      cond do
        #Tweet
        action == 1 ->
          GenServer.cast(String.to_atom(to_string(user)),{:send_tweets, user, num_users})
        #Search a hashtag
        # action ==2 ->
        #   #Again we can search for one hashtag or multiple hashtags
        #   GenServer.cast(String.to_atom(to_string(user)),{:searchHashtags, user, hashtags})
      end
    end)
  end
end
