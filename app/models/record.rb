class Record < ActiveRecord::Base
	include PgSearch
  	pg_search_scope :search_title, :against => [:title]
  	pg_search_scope :search_author, :against => [:author]
  	pg_search_scope :search_keyword, :against => [:author, :title]
end
