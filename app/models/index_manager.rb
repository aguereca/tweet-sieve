class IndexManager
  def self.create_index(index_name, options={})
    client     = Tweet.gateway.client
    #index_name = Tweet.index_name

    client.indices.delete index: index_name rescue nil if options[:force]

    settings = Tweet.settings.to_hash
    mappings = Tweet.mappings.to_hash

    client.indices.create index: index_name,
                          body: {
                            settings: settings.to_hash,
                            mappings: mappings.to_hash }
  end
end
