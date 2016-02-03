class Tweet
  include Elasticsearch::Persistence::Model
  include Elasticsearch::Model::Naming::InstanceMethods

  app_config = Rails.application.config
  Elasticsearch::Model.client = Elasticsearch::Client.new log: true,
                                                          host: app_config.elasticsearch_server

  index_name Rails.application.config.kafka_topic

  attribute :id, String, presence: true, mapping: { type: 'string',
                                                    index: 'not_analyzed' }

  analyzed_and_raw = { fields: {
                         analyzed: { type: 'string', analyzer: 'standard' },
                         raw:  { type: 'string', index: 'not_analyzed' }
                       } }

  attribute :text, String, mapping: analyzed_and_raw

  attribute :geo, String, mapping: { type: 'object',
                                     properties: {
                                       coordinates: { type: 'geo_point',
                                                     geohash: true,
                                                     geohash_prefix: true,
                                                     geohash_precision: 6}
                                     }
                                   }

  attribute :user, Hash, mapping: { type: 'object',
                                    properties: {
                                      id: {type: 'string',
                                           index: 'not_analyzed'},
                                      screen_name: {type: 'string',
                                                    index: 'not_analyzed'},
                                      name: {type: 'string',
                                             index: 'not_analyzed'},
                                      profile_image_url: {index: 'not_analyzed',
                                                          type: 'string'}
                                    }
                                  }

  #
  # TODO: Index 'place' object to consider geo-polygon on search
  #

  # Format reference: http://www.joda.org/joda-time/apidocs/org/joda/time/format/DateTimeFormat.html
  attribute :created_at, Time, mapping: { type: 'date'}


  def self.top_tweets(location, keywords, fields, size, radius)
    query = {
      query: {match_all:{}},
      _source: fields,
      sort: {'created_at': {'order': 'desc'}},
      size: size
    }
    unless location.nil?
      query[:query] = {
        filtered: {
          filter: {
            geohash_cell: {
              "geo.coordinates": {
                lat: location[0],
                lon: location[1]
              },
              precision: "#{radius}miles",
              neighbors: true
            }
          }
        }
      }
    end
    unless keywords.nil?
      sub_q = {
        match: { text: keywords }
      }
      if query[:query].has_key? :filtered
        query[:query][:filtered][:query] = sub_q
      else
        query[:query] = sub_q
      end
    end

    Tweet.search(query)
  end

end
