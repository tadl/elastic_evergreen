class Record < ActiveRecord::Base
	include PgSearch
	include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
  	
  	pg_search_scope :search_title, :against => [:title]
  	pg_search_scope :search_author, :against => [:author]
  	pg_search_scope :search_keyword, :against => [:author, :title]
end
