require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TweetSieve
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true


    # Load the app's custom environment variables here, so that they are loaded before environments/*.rb
    app_environment_variables = File.join(Rails.root, 'config', 'app_environment_variables.rb')
    load(app_environment_variables) if File.exists?(app_environment_variables)

    # Tweet-sieve vars (defined in file 'config/app_environment_variables.rb')
    config.twitter_api_key =       ENV['TWITTER_API_KEY']
    config.twitter_api_secret =    ENV['TWITTER_API_SECRET']
    config.twitter_access_token =  ENV['TWITTER_ACCESS_TOKEN']
    config.twitter_access_secret = ENV['TWITTER_ACCESS_SECRET']

    config.kafka_host =            ENV['KAFKA_HOST']
    config.kafka_port =            ENV['KAFKA_PORT']
    config.kafka_topic =           ENV['KAFKA_TOPIC']

    config.elasticsearch_server =  ENV['ELASTICSEARCH_SERVER']


    # App defaults not dependent on ENV vars
    config.kafka_client_id = 'tweet-sieve-app'
    config.kafka_sync_each = 100
    config.tweetstreaming_area = [-180,-90,180,90] # All world
    config.max_keep_indexes = 24 # 24 Hours
  end
end
