namespace :tweetsieve do
  desc "Consume new Kafka tweetstream topic and index tweets"
  task :tweet_indexer => :environment do
    # TODO: Store latest indexed offset on Redis
    indexer = IndexingService.new(:latest_offset)
    indexer.start_indexing(by: :hour)
  end

  desc "REINDEX existing and new tweets on Kafka tweetstream topic"
  task :reindex_tweets => :environment do
    indexer = IndexingService.new(:earliest_offset)
    indexer.start_indexing(by: :hour)
  end
end
