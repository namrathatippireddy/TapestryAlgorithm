defmodule Client do
  def init(client_state) do
    state = %{
      "engine_pid" => Enum.at(client_state, 0)
      # {}"users_list" => Enum.at(client_state,0)
    }
    Enum.each(1..10, fn hashtag ->
      hashtag_id = "#h#{hashtag}"
      :ets.insert_new(:hashtags, {hashtag_id, []})
    end)

    {:ok, state}
  end

  def handle_cast({:register, user_id}, state) do
    {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(engine_name, {:register_users, user_id})
    {:noreply, state}
  end

  def handle_cast({:send_tweets,user_id,num_users}, state) do
    IO.puts "Inside send tweets"
    {:ok, engine_name} = Map.fetch(state, "engine_pid")
    #n = Enum.random(1..num_users)
    tweet_content = prepare_tweet(user_id, num_users)
    IO.puts "Tweet content is #{tweet_content}"
    GenServer.cast(engine_name, {:handle_tweet, user_id, tweet_content})
    {:noreply, state}
  end

  def prepare_tweet(user_id, num_users) do
    IO.puts "Inside prepare_tweet"
    list1 = [1,2,3,4]
    random_tweet = Enum.random(list1)

    tweet = cond do
      random_tweet == 1 ->
        #pick a hashtag randomly and insert it into the tweet content
        no_hashtags=Enum.random(1..2)
        cond do
          no_hashtags==1 ->
            n = Enum.random(1..10)
            hashtag = "#h#{n}"
            "This is a string with  hashtag #{hashtag}"
          no_hashtags==2 ->
            n1 = Enum.random(1..10)
            hashtag1= "#h#{n1}"
            n2 = Enum.random(1..10)
            hashtag2= "#h#{n2}"
            "This is a string with  hashtag #{hashtag1} and #{hashtag2}"
        end
      random_tweet == 2 ->
        no_mentions = Enum.random(1..2)
        cond do
          no_mentions ==1 ->
            user = Enum.random(1..num_users)
            mention = "@#{user}"
            "This is a string with mention id #{mention}"
          no_mentions ==2 ->
            user1 = Enum.random(1..num_users)
            mention1 = "@#{user1}"
            user2 = Enum.random(1..num_users)
            mention2 = "@#{user2}"
            "This is a string with mention ids #{mention1} and #{mention2}"
          end
      random_tweet == 3 ->
        n1 = Enum.random(1..10)
        hashtag1= "#h#{n1}"
        user1 = Enum.random(1..num_users)
        mention1 = "@#{user1}"
        "This is a string with one mention #{mention1} and one hashtag #{hashtag1}"
      random_tweet == 4 ->
        "This is just a normal tweet with no mentions or hashtags"
      end

  end

  def handle_cast({:subscribe, user_id, num_users}, state) do
    IO.puts "Inside subscribe"
    userToSub = Enum.random(1..num_users)
    {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(engine_name, {:subscribe_user, userToSub, user_id})
    {:noreply, state}
  end

  #If anyone we subscribed to tweets, receive it
  def handle_cast({:receiveTweet, tweet_content}, state) do
    IO.puts "receiving tweets"
    IO.puts tweet_content
    {:noreply, state}
  end

  #Search for tweets with a given hashtag
  #GenServer callback to query for tweets with given hashtags
  def handle_cast({:searchHashtags, user_id, hashtags}, state) do
    IO.puts "Client will search for a hashtag"
    {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(engine_name, {:search_hashtags, user_id, hashtags})
    {:noreply, state}
  end

  def handle_cast({:search_hashtag_reply, tweets}, state) do
    IO.puts "receiving tweets with given hashtags"
    IO.puts tweets
    {:noreply, state}
  end

end
