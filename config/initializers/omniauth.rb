Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :twitter, ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET']
  provider :twitter, "H3bYC0UCRn3nl86UaV7ffA", "JcyTjI33DDGMa8rWn1ofdMgzhycnHdmqcSfoApoddI"
end