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
                                       cordinates: { type: 'geo_point',
                                                     geohash: true,
                                                     geohash_prefix: true,
                                                     geohash_precision: 10}
                                     }
                                   }

  attribute :user, Hash, mapping: { type: 'object',
                                    properties: {
                                      id: {type: 'string',
                                           index: 'not_analyzed'},
                                      name: {type: 'string',
                                             mapping: analyzed_and_raw},
                                      default_profile_image: {index: 'not_analyzed',
                                                              type: 'string'}
                                    }
                                  }

  #
  # TODO: Index 'place' object to consider geo-polygon on search
  #

  # Format reference: http://www.joda.org/joda-time/apidocs/org/joda/time/format/DateTimeFormat.html
  attribute :created_at, Time, mapping: { type: 'date'}
end
