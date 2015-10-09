class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	search_term = URI.unescape(params[:query]) rescue ''
  	search_type = params[:search_type] rescue nil
    available = params[:available] rescue false
    if params[:page]
      page = params[:page].to_i * 48
    else
      page = 0
    end
    search_job = Searchjob.new
    if search_type.nil? || search_type == 'keyword'
    	response = search_job.keyword(search_term, page, available)
  	elsif search_type == 'author'
      response = search_job.author(search_term, page, available)
  	elsif search_type == 'title'
      response = search_job.title(search_term, page, available)
    elsif search_type == 'subject'
      response = search_job.subject(search_term, page, available)
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
