defmodule Engine do
  use GenServer

  def init(engine_state) do
    state = %{}
    :ets.new(:users, [:set, :public, :named_table])
    :ets.new(:following, [:set, :public, :named_table])

    :ets.new(:tweets, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:hashtags, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:mentionIds, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:loggedInUsers, [:set, :public, :named_table])

    {:ok, state}
  end

  def handle_cast({:register_users, user_id}, state) do
    :ets.insert_new(:users, {user_id, []})
    mention_id = "@#{user_id}"
    #IO.puts("Mention id is #{mention_id}")
    :ets.insert_new(:loggedInUsers, {user_id, true})
    :ets.insert_new(:mentionIds, {mention_id,[]})
    {:noreply, state}
  end

  def handle_cast({:handle_tweet, user_id, tweet_content}, state) do
    #Once an user tweets, the engine should get the subscribers of the user and then extract the
    #hashtags and mentions, if there is hashtag, then insert the tweet into the table with that hashtag as key
    #if there is a mention, then get the user who is mentioned and add it to the mentions table
    #Also while sending the tweet to the subscriber, check if he is logged in using the loggedIn table, if yes, then send it.

    #Searching for hashtags or mentions
    #We can give the query processing time here, start the timer when the query has been received and calcuate the endtime when the tweet
    #has been sent to all the subscribers
    list_of_hts = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet_content)
    list_of_mentions = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet_content)
    if(length(list_of_hts) > 0) do
    Enum.each(list_of_hts, fn each_ht->
      ht_tweet = cond do
        :ets.member(:hashtags, each_ht) ->
          [{_, tweets_for_ht}] = :ets.lookup(:hashtags, each_ht)
          tweets_for_ht ++ [tweet_content]
        true -> [tweet_content]
      end
      :ets.insert(:hashtags, {each_ht, ht_tweet})
    end)
  end

  if(length(list_of_mentions) > 0) do
    Enum.each(list_of_mentions, fn each_mention ->
      mention_tweet = cond do
        :ets.member(:mentionIds, each_mention) ->
          [{_, tweets_for_mention}] = :ets.lookup(:mentionIds, each_mention)
          tweets_for_mention ++ [tweet_content]
        true -> [tweet_content]
      end
      :ets.insert(:mentionIds, {each_mention, mention_tweet})
    end)
  end

  #get the subscribers for the given user_id and forward the tweet
  [{_, subscriber_list}] = :ets.lookup(:users, user_id)
  Enum.each(subscriber_list, fn subscriber ->
      GenServer.cast(subscriber, {:receiveTweet, tweet_content})
  end)



  end

  #UserToSub_id is the one you want to follow, user_id our id
  def handle_cast({:subscribe_user, userToSubscibe_id, user_id}, state) do
    #we are updating the followers list of UserToSub_id
    [{userToSubscibe_id, followers}] = :ets.lookup(:users, userToSubscibe_id)
    followers = followers ++ [user_id]
    :ets.insert(:users, {userToSubscibe_id, followers})

    #we also update the following table of the present user who called this function
    follow = cond do
      :ets.member(:following, user_id) ->
        [{_, listOfPeopleIFollow}] = :ets.lookup(:following, user_id)
        listOfPeopleIFollow ++ [userToSubscibe_id]
      true -> [userToSubscibe_id]
    end
    :ets.insert(:following, {user_id, follow})
    {:noreply, state}
  end

  def handle_cast({:search_hashtags, user_id, search_hashtags}, state) do
    Enum.filter(search_hashtags, fn search_hashtag->
      tweets_for_hashtag = cond do
          :ets.member(:hashtags, search_hashtag) ->
          [{_, listOfTweetsforHashtag}] = :ets.lookup(:hashtags, search_hashtag)
          listOfTweetsforHashtag
        true -> nil
      end
      GenServer.cast(user_id, {:search_hashtag_reply, tweets_for_hashtag})
    end)
      {:noreply, state}
  end


end
