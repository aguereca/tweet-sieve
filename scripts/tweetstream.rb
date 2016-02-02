require 'tweetstream'

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(root, "config", "environment")

TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_API_KEY']
  config.consumer_secret    = ENV['TWITTER_API_SECRET']
  config.oauth_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_ACCESS_SECRET']
  config.auth_method        = :oauth
end

daemon = TweetStream::Daemon.new('tracker', :log_output => true)
daemon.on_inited do
  ActiveRecord::Base.connection.reconnect!
  ActiveRecord::Base.logger = Logger.new(
    File.open(File.join(root, "log", "stream.log"), 'w+'))
end

daemon.locations(-180,-90,180,90) do |tweet|
  p tweet.inspect
end
