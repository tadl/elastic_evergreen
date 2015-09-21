class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	@record_count = Record.all.count
  	search_term = URI.unescape(params[:query]) rescue ''
  	search_type = params[:search_type] rescue nil
    if search_type.nil? || search_type == 'keyword'
    	response = Record.search query: 
      {
        bool:
        { 
          should:[ 
            {
              multi_match: {
                query: search_term,
                fields: ['title^3','author^2', 'abstract'],
              }
            },
            {
              multi_match: {
                query: search_term,
                fields: ['title^3','author^4', 'abstract'],
                fuzziness: 2
              }
            }
          ]
        }
      },
      size: 24,
      from: 0
  	elsif search_type == 'author'
        # response = Record.search query: {match: { author: {query: author, fuzziness: 1} } }
        response = Record.search min_score: 0.1, query: {bool:{ should:[{match: {author: search_term}}, {match_phrase: {author: search_term}}, {fuzzy: {author: search_term}}]}}
        
  	elsif search_type == 'title'
        response = Record.search query: {multi_match: {type: 'most_fields', query: search_term, fields: ['title', 'title.folded']} }
  	end
    @records = response.records
  	respond_to do |format|
      format.html
      format.json {render json: @records}
    end
  end

  def about
  end
end
