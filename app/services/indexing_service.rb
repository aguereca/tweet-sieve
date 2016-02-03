require 'poseidon'

class IndexingService

  def initialize(offset)
    @app_config = Rails.application.config
    @kafka_consumer = Poseidon::PartitionConsumer.new(
      @app_config.kafka_client_id,
      @app_config.kafka_host,
      @app_config.kafka_port,
      @app_config.kafka_topic,
      0, offset)
  end


  def start_indexing(by: :hour)
    sync_index_names()
    loop do
      @kafka_consumer.fetch.each do |message|
        tweet = JSON.parse message.value
        # NOTE: For now only index tweets with geo.coordinates
        unless tweet['geo'].nil?
          indexable_tweet = self.indexable_tweet tweet
          new_index_name = [@app_config.kafka_topic,
                            self.index_sufix(indexable_tweet['created_at'],
                                             by)].join("_")
          unless @index_names.include? new_index_name
            # New index required ...
            IndexManager.create_index(new_index_name)
            self.sync_index_names
          end
          #Tweet.__elasticsearch__.create_index!
          tweet_doc = Tweet.new indexable_tweet
          # TODO: Fix this because changing the instance index_name
          #       doesn't index on updated index, only works updating the class,
          #       this is a problem with multiple processes
          Tweet.index_name = new_index_name
          tweet_doc.save
        end
      end
    end
  end

  def indexable_tweet(raw_tweet)
    {
      id: raw_tweet['id'],
      text: raw_tweet['text'],
      geo: {
        coordinates: raw_tweet['geo']['coordinates']
      },
      user: {
        id: raw_tweet['user']['id'],
        name: raw_tweet['user']['name'],
        default_profile_image: raw_tweet['user']['default_profile_image']
      },
      created_at: Time.parse(raw_tweet['created_at'])
    }
  end

  protected

  def sync_index_names()
    # "Cache" of indexes on Cluster
    @index_names = Tweet.gateway.client.cat.indices
  end

  def index_sufix(date, by)
    format = nil
    case by
    when :hour
      format = "%y%m%d%M"
    when :day
      format = "%y%m%d00"
    end
    date.strftime(format)
  end

end