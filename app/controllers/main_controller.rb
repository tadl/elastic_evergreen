class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	search_term = URI.unescape(params[:query]) rescue ''
  	search_type = params[:search_type] rescue nil
    search_job = Searchjob.new
    if search_type.nil? || search_type == 'keyword'
    	response = search_job.keyword(search_term)
  	elsif search_type == 'author'
      response = search_job.author(search_term)
  	elsif search_type == 'title'
      response = search_job.title(search_term)
    elsif search_type == 'record_id'
      response = search_job.record_id(search_term)
  	end
  	respond_to do |format|
      format.html
      format.json {render json: response}
    end
  end

  def about
  end
end
