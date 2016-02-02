class Tweet
  include Elasticsearch::Persistence::Model

  index_name [Rails.application.engine_name, Rails.env].join('-')


  attribute :id, String, presence: true, mapping: { index: 'not_analyzed' }

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
                                      id: {index: 'not_analyzed'},
                                      name: {mapping: analyzed_and_raw},
                                      deafault_profile_image: {index: 'not_analyzed'}
                                  }

  #
  # TODO: Index 'place' object to consider geo-polygon on search
  #

  # Format reference: http://www.joda.org/joda-time/apidocs/org/joda/time/format/DateTimeFormat.html
  attribute :created_at, Date, mapping: { type: 'date',
                                          format: 'EEE MMM dd kk:mm:ss ZZ yyyy'}
end
