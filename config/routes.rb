Kaladin::Application.routes.draw do
  root :to => "statics#home"
  
  match "/tweet" => "user#tweet", :as => :tweet
  match "/logout" => "sessions#destroy", :as => :logout
  match "/lda" => "statics#lda", :as => :get_lda
  match "/svm" => "statics#svm", :as => :get_svm
  
  match "/auth/:provider/callback" => "sessions#create"
  
  post '/statics/friends', :to => 'statics#all_friends', :as => :get_friends
end
