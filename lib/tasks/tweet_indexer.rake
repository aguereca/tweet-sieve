require 'poseidon'

app_config = Rails.application.config

namespace :tweetsieve do
  desc "Consume Kafka tweetstream topic and indexes tweets"
  task :tweet_indexer => :environment do
    consumer = Poseidon::PartitionConsumer.new(app_config.kafka_client_id,
                                               app_config.kafka_host,
                                               app_config.kafka_port,
                                               app_config.kafka_topic,
                                               0, :earliest_offset)

    loop do
      messages = consumer.fetch
      messages.each do |message|
        #p consumer.highwater_mark
        tweet = JSON.parse message.value
        # NOTE: For now only index tweets with geo.coordinates
        unless tweet['geo'].nil?
          Tweet.create id: tweet['id'],
                       text: tweet['text'],
                       geo: {
                         coordinates: tweet['geo']['coordinates']
                       },
                       user: {
                         id: tweet['user']['id'],
                         name: tweet['user']['name'],
                         default_profile_image: tweet['user']['default_profile_image']
                       },
                       created_at: Time.parse(tweet['created_at'])
        end
      end
    end
  end
end
