class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	search_term = URI.unescape(params[:query]) rescue ''
  	search_type = params[:search_type] rescue nil
    available = params[:available] rescue false
    subjects = params[:subjects] rescue nil
    genres = params[:genres] rescue nil
    series = params[:series] rescue nil
    authors = params[:authors] rescue nil
    format_type = params[:format_type] rescue nil
    location_code = params[:location_code] rescue nil
    if params[:page]
      page = params[:page].to_i * 24
    else
      page = 0
    end
    search_job = Searchjob.new
    response = search_job.get_results(search_term,
																			search_type,
																			format_type,
																			page,
																			available,
																			subjects,
																			genres,
																			series,
																			authors,
																			location_code)
  	respond_to do |format|
      format.html
      format.json {render json: response}
    end
  end

  def about
  end
end
