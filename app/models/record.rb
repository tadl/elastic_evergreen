class Record < ActiveRecord::Base
	include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

    if ENV.has_key?('ES_INDEX')
        index_name ENV['ES_INDEX']
    end

end
