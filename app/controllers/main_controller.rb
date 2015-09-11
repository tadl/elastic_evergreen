class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	@record_count = Record.all.count
  	keyword = URI.unescape(params[:keyword]) rescue ''
  	title = URI.unescape(params[:title]) rescue ''
  	author = URI.unescape(params[:author]) rescue ''
  	search_type = params[:search_type] rescue nil
    if search_type.nil? || search_type == 'keyword'
        @records = Record.search(keyword)
    elsif search_type == 'pgkeyword'
        # Use pg_search here
    	@records = Record.search_keyword(keyword + ' ' + title + ' ' + author)
  	elsif search_type == 'author'
        # response = Record.search query: {match: { author: {query: author, fuzziness: 1} } }
        response = Record.search min_score: 0.1, query: {bool:{ should:[{match: {author: author}}, {match_phrase: {author: author}}, {fuzzy: {author: author}}]}}
        # @records = response
        @records = response.records
  	elsif search_type == 'title'
        @records = Record.search query: {multi_match: {type: 'most_fields', query: title, fields: ['title', 'title.folded']} }
  	end
  	respond_to do |format|
      format.html
      format.json {render json: @records}
    end
  end

  def about
  end
end
