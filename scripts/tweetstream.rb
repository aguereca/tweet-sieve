#
# Twitter streaming api client. (Daemon)
#
# Run as service: ruby scripts/tweetstream.rb (start|stop|run)
#

require 'tweetstream'
#require 'poseidon'


ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(root, "config", "environment")
app_config = Rails.application.config


TweetStream.configure do |config|
  config.consumer_key       = app_config.twitter_api_key
  config.consumer_secret    = app_config.twitter_api_secret
  config.oauth_token        = app_config.twitter_access_token
  config.oauth_token_secret = app_config.twitter_access_secret
  config.auth_method        = :oauth
end

daemon = TweetStream::Daemon.new('tracker', :log_output => true)
daemonlogger = nil
daemon.on_inited do
  ActiveRecord::Base.connection.reconnect!
  # File connection of loggers
  # Reference: http://stackoverflow.com/questions/14808226/ruby-logger-and-daemons
  ActiveRecord::Base.logger = Logger.new(File.open(File.join(root, "log", "activerecord.log"), 'w+'))
  Poseidon.logger = Logger.new(File.open(File.join(root, "log", "poseidon.log"), 'w+'))
  daemonlogger = Logger.new(File.open(File.join(root, "log", "tweetstream.log"), 'w+'))
   daemonlogger.info "Processing twitter stream ..."
end
daemon.on_error do |message|
  daemonlogger.warn "Error: #{message}"
end
daemon.on_reconnect do |timeout, retries|
  daemonlogger.info "Reconnect: #{timeout} - #{retries}"
end
daemon.on_limit do |message|
  daemonlogger.warn "Limit: #{message}"
end
daemon.on_enhance_your_calm do
  daemonlogger.warn "Enhance your calm!:"
end

kafka_server = "#{app_config.kafka_host}:#{app_config.kafka_port}"
producer = Poseidon::Producer.new([kafka_server], app_config.kafka_client_id)

messages = []
daemon.locations(*app_config.tweetstreaming_area) do |tweet|
  # NOTE: To reduce space used by Kafka we are not storing tweets
  #       without geo.coordinates, once we add code to index
  #       the geo-polygon of 'place', this limitation can be lifted
  unless tweet.geo.coordinates.nil?
    messages << Poseidon::MessageToSend.new(app_config.kafka_topic,
                                            JSON.dump(tweet.to_hash))
    # NOTE: Since :async isn't yet implemented on Poseidon, we'll sync each
    #       'sync_each' messages, might be implemented also with a timeout
    #       to ensure each 'sync_timeout' seconds max
    if messages.length >= app_config.kafka_sync_each
      producer.send_messages(messages)
    end
  end
end
