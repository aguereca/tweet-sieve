#
# Twitter streaming api client.
#
# Run as service: ruby scripts/tweetstream.rb (start|stop|run)
#

require 'tweetstream'
#require 'poseidon'


ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
# Load env variables, without loading application
require File.join(root, "config", "app_environment_variables")
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

producer = Poseidon::Producer.new([app_config.kafka_server],
                                  app_config.kafka_client_id,
                                  :type => :sync)

messages = []
daemon.locations(*app_config.tweetstreaming_area) do |tweet|
  messages << Poseidon::MessageToSend.new(app_config.kafka_topic,
                                          tweet.to_hash.to_s)
  # NOTE: Since :async isn't yet implemented on Poseidon, we'll sync each
  #       'sync_each' messages, might be implemented also with a timeout
  #       to ensure each 'sync_timeout' seconds max
  if messages.length >= app_config.kafka_sync_each
    producer.send_messages(messages)
  end
end
