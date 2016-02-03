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
                            self.index_sufix(indexable_tweet[:created_at],
                                             by)].join("_")
          unless @index_names.include? new_index_name
            self.create_new_index(new_index_name)
          end
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
        screen_name: raw_tweet['user']['screen_name'],
        name: raw_tweet['user']['name'],
        profile_image_url: raw_tweet['user']['profile_image_url']
      },
      created_at: Time.parse(raw_tweet['created_at'])
    }
  end


  def create_new_index(index_name)
    IndexManager.create_index(index_name)
    Tweet.gateway.client.indices.put_alias index: index_name,
                                           name: @app_config.kafka_topic
    self.sync_index_names
    # Prune indexes, only keep max expected
    self.prune_indexes
  end


  def prune_indexes(keep: @app_config.max_keep_indexes)
    if @index_names.length > keep
      to_remove = @index_names.slice!(keep, @index_names.length)
      to_remove.each do |index|
        Tweet.gateway.client.indices.delete index: index
      end
    end
  end


  protected


  def sync_index_names()
    # "Cache" of indexes on Cluster
    @index_names = Tweet.gateway.client.cat.indices.split("\n").map do |raw|
      raw.split(" ")[2]
    end
    @index_names.sort!
    @index_names.reverse!
  end


  def index_sufix(date, by)
    format = nil
    case by
    when :minute
      # NOTE: Not used for now
      format = "%y%m%d%H%M"
    when :hour
      format = "%y%m%d%H"
    when :day
      # NOTE: Not used for now
      format = "%y%m%d"
    end
    date.strftime(format)
  end

end
