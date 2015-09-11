class Record < ActiveRecord::Base
	include PgSearch
	include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
  	
  	pg_search_scope :search_title, :against => [:title], :using => {:tsearch => {:prefix => true}}
  	pg_search_scope :search_author, :against => [:author], :using => {:tsearch => {:prefix => true}}
  	pg_search_scope :search_keyword, :against => [:author, :title], :using => {:tsearch => {:prefix => true}}

    settings analysis: {analyzer: {folding: {tokenizer: 'standard', filter: ['lowercase', 'asciifolding']}}} do
        mappings do
            indexes :title, analyzer: 'english', fields: {folded: {type: 'string', analyzer: 'folding'}}
        end
    end
end
