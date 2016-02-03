namespace :tweetsieve do
  desc "Creates ElasticSearch indexes with correct mappings"
  task :init_indexes => :environment do
    IndexManager.create_index()
  end
end
