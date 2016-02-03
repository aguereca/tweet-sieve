# TweetSieve

Rails app to query live tweets around the globe. Tweets can be filtered by location and keywords. Map markers and Tweets list are interactive, feel free to click around!



## Installation

To execute locally is required to have access to Kafka and Elasticsearch, viw references for resources on the topic.
Rest of the document assumes those services are available.

1. Install gems:

```bash
bundle install
```


2. Setup environment by creating file `config/app_environment_variables.rb` using file `config/app_environment_variables.rb.template` as reference


3. Start service `tweetstream`:

```bash
ruby scripts/tweetstream.rb start
```


4. Validate that messages are being published to Kafka:

```bash
kafka-console-consumer.sh --zookeeper localhost:2181 --topic tweetstream --from-beginning
```
If consumer don't print new tweets, then validate your ENV settings and Kafka server


5. Run indexing rake task, there are two tasks for this purpose. Reindex tasks, reindex all messages on topic and keeps listening for new; Indexer task only index new messages.
Most of the time the reindex task is appropriate. Use `rake -T` as reference.
If needed, `nohup` or `supervisor` can be used to keep the indexer running on the background.

```bash
rake tweetsieve:reindex_tweets
```

Indexing service creates new indexes per hour and automatically prunes old indexes, by default app keeps 24 hours of data. Use Kafka `log.retention.hours` to control the retention policy on the service.


6. Start web server

```bash
sudo bundle exec rails s -p 80 -b '0.0.0.0' -d
```



## Usage

Application shows last 250 tweets globaly, each tweet corresponds to a marker in the map, clicking on a marker will show the original text and the author handle, also clicking on a row of the Tweets table will move the view port and map to the location of the tweet.

To filter Tweets by location, type the name of a city of place for example *San Francisco, CA* and only tweets of that location will be shown, use the `Radius` value to control the precision of the filter.

Tweet list can also be filtered by keywords, words typed will be matched against the tweet text, for now only full-word matches are shown.

Location and Keywords can be used in conjunction or independently to customize the tweets list.


### Known Issues:

- Radius is expressed in miles, but doesn't seem to be correct since most of the time a value several times larger than expected is required to include an area.
- Even though we are receiving from Twitter all tweets with some kind of location, we are only storing in Kafka and Indexing tweets that have geo.coordinates, there are some that don't have this value but instead have a location inferred by a *Place*, is pending to process this objects.


### Remaining Work

Lots of it:
- Write RSpec tests
- Validate and improve performance
- Fix failed attempt to use Docker for deployment on AWS
