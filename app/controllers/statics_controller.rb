class StaticsController < ApplicationController
  
  def twitter_client
    Twitter::REST::Client.new do |config|
      config.consumer_key =  "H3bYC0UCRn3nl86UaV7ffA" 
      config.consumer_secret = "JcyTjI33DDGMa8rWn1ofdMgzhycnHdmqcSfoApoddI"
      config.access_token = current_user.token
      config.access_token_secret = current_user.secret
    end
  end


  def all_friends(max_attempts = 100)
    # in theory, one failed attempt will occur every 15 minutes, so this could be long-running
    # with a long list of friends
    num_attempts = 0
    client = twitter_client
    @allfriends = []
    running_count = 0
    cursor = -1
    while (cursor != 0) do
      begin
        num_attempts += 1
        # 200 is max, see https://dev.twitter.com/docs/api/1.1/get/friends/list
        friends = client.friends(current_user.nickname, {:cursor => cursor, :count => 200} )
        friends.each do |f|
          running_count += 1
          @allfriends << f.screen_name
        end
        puts "#{running_count} done"
        cursor = friends.next_cursor
        break if cursor == 0
      rescue Twitter::Error::TooManyRequests => error
        if num_attempts <= max_attempts
          cursor = friends.next_cursor if friends && friends.next_cursor
          puts "#{running_count} done from rescue block..."
          puts "Hit rate limit, sleeping for #{error.rate_limit.reset_in}..."
          sleep error.rate_limit.reset_in
          retry
        else
          raise
        end
      end
    end
  end
end
