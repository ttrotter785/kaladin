require 'libsvm'

class StaticsController < ApplicationController
  
  def twitter_client
    Twitter::REST::Client.new do |config|
      config.consumer_key =  "H3bYC0UCRn3nl86UaV7ffA" 
      config.consumer_secret = "JcyTjI33DDGMa8rWn1ofdMgzhycnHdmqcSfoApoddI"
      config.access_token = current_user.token
      config.access_token_secret = current_user.secret
    end
  end

  def lda
    
    #stopwords_list = "a,s,able,about,above,according,accordingly,across,actually,after,afterwards,again,against,ain,t,all,allow,allows,almost,alone,along,already,also,although,always,am,among,amongst,an,and,another,any,anybody,anyhow,anyone,anything,anyway,anyways,anywhere,apart,appear,appreciate,appropriate,are,aren,t,around,as,aside,ask,asking,associated,at,available,away,awfully,be,became,because,become,becomes,becoming,been,before,beforehand,behind,being,believe,below,beside,besides,best,better,between,beyond,both,brief,but,by,c,mon,c,s,came,can,can,t,cannot,cant,cause,causes,certain,certainly,changes,clearly,co,com,come,comes,concerning,consequently,consider,considering,contain,containing,contains,corresponding,could,couldn,t,course,currently,definitely,described,despite,did,didn,t,different,do,does,doesn,t,doing,don,t,done,down,downwards,during,each,edu,eg,eight,either,else,elsewhere,enough,entirely,especially,et,etc,even,ever,every,everybody,everyone,everything,everywhere,ex,exactly,example,except,far,few,fifth,first,five,followed,following,follows,for,former,formerly,forth,four,from,further,furthermore,get,gets,getting,given,gives,go,goes,going,gone,got,gotten,greetings,had,hadn,t,happens,hardly,has,hasn,t,have,haven,t,having,he,he,s,hello,help,hence,her,here,here,s,hereafter,hereby,herein,hereupon,hers,herself,hi,him,himself,his,hither,hopefully,how,howbeit,however,i,d,i,ll,i,m,i,ve,ie,if,ignored,immediate,in,inasmuch,inc,indeed,indicate,indicated,indicates,inner,insofar,instead,into,inward,is,isn,t,it,it,d,it,ll,it,s,its,itself,just,keep,keeps,kept,know,knows,known,last,lately,later,latter,latterly,least,less,lest,let,let,s,like,liked,likely,little,look,looking,looks,ltd,mainly,many,may,maybe,me,mean,meanwhile,merely,might,more,moreover,most,mostly,much,must,my,myself,name,namely,nd,near,nearly,necessary,need,needs,neither,never,nevertheless,new,next,nine,no,nobody,non,none,noone,nor,normally,not,nothing,novel,now,nowhere,obviously,of,off,often,oh,ok,okay,old,on,once,one,ones,only,onto,or,other,others,otherwise,ought,our,ours,ourselves,out,outside,over,overall,own,particular,particularly,per,perhaps,placed,please,plus,possible,presumably,probably,provides,que,quite,qv,rather,rd,re,really,reasonably,regarding,regardless,regards,relatively,respectively,right,said,same,saw,say,saying,says,second,secondly,see,seeing,seem,seemed,seeming,seems,seen,self,selves,sensible,sent,serious,seriously,seven,several,shall,she,should,shouldn,t,since,six,so,some,somebody,somehow,someone,something,sometime,sometimes,somewhat,somewhere,soon,sorry,specified,specify,specifying,still,sub,such,sup,sure,t,s,take,taken,tell,tends,th,than,thank,thanks,thanx,that,that,s,thats,the,their,theirs,them,themselves,then,thence,there,there,s,thereafter,thereby,therefore,therein,theres,thereupon,these,they,they,d,they,ll,they,re,they,ve,think,third,this,thorough,thoroughly,those,though,three,through,throughout,thru,thus,to,together,too,took,toward,towards,tried,tries,truly,try,trying,twice,two,un,under,unfortunately,unless,unlikely,until,unto,up,upon,us,use,used,useful,uses,using,usually,value,various,very,via,viz,vs,want,wants,was,wasn,t,way,we,we,d,we,ll,we,re,we,ve,welcome,well,went,were,weren,t,what,what,s,whatever,when,whence,whenever,where,where,s,whereafter,whereas,whereby,wherein,whereupon,wherever,whether,which,while,whither,who,who,s,whoever,whole,whom,whose,why,will,willing,wish,with,within,without,won,t,wonder,would,would,wouldn,t,yes,yet,you,you,d,you,ll,you,re,you,ve,your,yours,yourself,yourselves,zero".split(',')

    @topics = []
    corpus = Lda::Corpus.new
    corpus.add_document(Lda::TextDocument.new(corpus, "a lion is a wild feline animal"))
    corpus.add_document(Lda::TextDocument.new(corpus, "a dog is a friendly animal"))
    corpus.add_document(Lda::TextDocument.new(corpus, "a cat is a feline animal"))
     
    lda = Lda::Lda.new(corpus)
    lda.verbose = false
    lda.num_topics = (2)
    lda.em('random')
    @topics = lda.top_words(3)
 
    #@topics = lda.top_words(words_per_topic = 1)     # print the topic 20 words per topic
  end
  
  def svm(max_attempts = 100)
    feature_vectors = []
    test_vectors = []
     @lists = []
     @cats = {}
     num_attempts = 0
     words = []
    client = twitter_client
    alllists = []
    tweets = []
    formatted_tweets = []
    test_formatted_tweets = []
    labels = []
    train_labels = []
    test_labels = []
    running_count = 0
    cursor = -1
    tweet_counter = 0
    while (cursor != 0) do
      begin
        num_attempts += 1
        # 200 is max, see https://dev.twitter.com/docs/api/1.1/get/friends/list
        friends = client.friends(current_user.nickname, {:cursor => cursor, :count => 5} )
        friends.each do |f|
          running_count += 1
          #get all lists
          #options = {:count => 20, :include_rts => false}
          listcounter = 0
          alllists << client.lists(f.screen_name) #get_all_tweets(f)
          alllists.each do |lists|
            lists.each do |l|
             @cats[l.name] = nil 
             labels[listcounter] = l.name
             listcounter += 1
            end
          end
          
          alllists.each do |lists|
            lists.each do |l|
            #  formatted_tweet = remove_urls_and_users(tweet.text.dup)
            #  puts formatted_tweet
              formatted_tweets.clear
              test_formatted_tweets.clear
              
              tweets = client.list_timeline(l.id)
              tweets.each do |tweet|
                tweet_counter +=1
                
                formatted_tweet = remove_urls_and_users(tweet.text.dup)
                #puts l.name + " " + formatted_tweet
                if tweet_counter % 2 == 1
                  formatted_tweets << formatted_tweet.split(/\W/).reject(&:empty?)
                  train_labels << labels.index(l.name)
                  feature_vectors << labels.index(l.name)
                else
                  test_formatted_tweets << formatted_tweet.split(/\W/).reject(&:empty?)
                  test_labels << labels.index(l.name) #labels[l.name]
                  test_vectors << labels.index(l.name)
                end
                
                @cats[l.name] = (test_formatted_tweets + formatted_tweets).flatten.uniq
                
              end
            end
          end
          break if running_count == 1
        end
        puts "#{running_count} done"
        
        dictionary = (test_formatted_tweets + formatted_tweets).flatten.uniq
        puts "Global dictionary: \n #{dictionary.inspect}\n\n"
        
        #feature_vectors = formatted_tweets.map { |doc| dictionary.map{|x| doc.(x) ? 1 : 0} }
        #test_vectors = test_formatted_tweets.map { |doc| dictionary.map{|x| doc.include?(x) ? 1 : 0} }
        
        puts "First training vector: #{feature_vectors.first.inspect}\n"
        puts "First test vector: #{test_vectors.first.inspect}\n"
        
        
        # Define kernel parameters -- we'll stick with the defaults
        sp = Libsvm::Problem.new
        pa = Libsvm::SvmParameter.new
        
        pa.cache_size = 1 # in megabytes
        
        pa.eps = 0.001
        pa.c = 10


        #pa.C = 100
        #pa.svm_type = NU_SVC
        #pa.degree = 1
        #pa.coef0 = 0
        #pa.eps= 0.001
        puts train_labels
        puts feature_vectors
        
        
        examples = [ [1,0,1], [-1,0,-1] ].map {|ary| Libsvm::Node.features(ary) }
        labels = [1, -1]

        sp.set_examples(labels, examples)

        # Add documents to the training set
        #train_labels.each_index { |i| sp.set_examples(train_labels[i], feature_vectors[i]) }
        
        # We're not sure which Kernel will perform best, so let's give each a try
        #kernels = [ POLY, RBF, SIGMOID ]
        #kernel_names = [ 'Polynomial', 'Radial basis function', 'Sigmoid' ]
        
        model = Libsvm::Model.train(sp, pa)

        pred = model.predict(Libsvm::Node.features(1, 1, 1))
        puts "Example [1, 1, 1] - Predicted #{pred}"
        
        
        break if running_count == 1
        cursor = friends.next_cursor
        break if cursor == 0
      rescue Twitter::Error::TooManyRequests => error
        #if num_attempts <= max_attempts
        #  cursor = friends.next_cursor if friends && friends.next_cursor
        #  puts "#{running_count} done from rescue block..."
        #  puts "Hit rate limit, sleeping for #{error.rate_limit.reset_in}..."
        #  sleep error.rate_limit.reset_in
        #  retry
        #else
          raise
        #end #if
      end #begin/try
      
    end #while
     
  end
  
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield max_id
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def get_all_tweets(user)
    collect_with_max_id do |max_id|
    options = {:count => 5, :include_rts => false}
    options[:max_id] = max_id unless max_id.nil?
    twitter_client.user_timeline(user, options)
    end
  end

  def all_friends(max_attempts = 100)
    # in theory, one failed attempt will occur every 15 minutes, so this could be long-running
    # with a long list of friends
    #regexps
    url = /( |^)http:\/\/([^\s]*\.[^\s]*)( |$)/
    user = /@(\w+)/
    
    corpus = Lda::Corpus.new
    @topics = []
              
    num_attempts = 0
    client = twitter_client
    alltweets = []
    running_count = 0
    cursor = -1
    while (cursor != 0) do
      begin
        num_attempts += 1
        # 200 is max, see https://dev.twitter.com/docs/api/1.1/get/friends/list
        friends = client.friends(current_user.nickname, {:cursor => cursor, :count => 15} )
        friends.each do |f|
          running_count += 1
          #@allfriends << f.screen_name
          options = {:count => 20, :include_rts => false}
          alltweets << client.user_timeline(f.screen_name, options) #get_all_tweets(f)
          alltweets.each do |timeline|
            timeline.each do |tweet|
              formatted_tweet = remove_urls_and_users(tweet.text.dup)
              puts formatted_tweet
              corpus.add_document(Lda::TextDocument.new(corpus, formatted_tweet))
            end
          end
          break if running_count == 20
        end
        puts "#{running_count} done"
        break if running_count == 20
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
        end #if
      end #begin/try
      
    end #while
    
    lda = Lda::Lda.new(corpus)
    lda.verbose = false
    lda.num_topics = (3)
    lda.em('random')
    @topics = lda.top_words(1)
    puts @topics
      
  end #method
  
  def remove_urls_and_users s
      #regexps
      url = /( |^)http:\/\/([^\s]*\.[^\s]*)( |$)/
      user = /@(\w+)/

      #replace @usernames with links to that user
      while s =~ user
          s.sub! "@#{$1}", ""
      end
  
      #replace urls with links
      while s =~ url
          name = $2
          s.sub! /( |^)http:\/\/#{name}( |$)/, ""
      end
      
      s.sub! "&", ""
      s.sub! "amp", ""
      s.sub! "RT", ""
      s.sub! "-", ""
      s
  end


end #class
