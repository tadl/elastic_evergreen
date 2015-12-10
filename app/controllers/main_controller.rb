class MainController < ApplicationController
	require 'open-uri'
	respond_to :html, :json
  def index
  	search_term = URI.decode(params[:query]) rescue ''  
  	search_type = params[:search_type] rescue nil
    available = params[:available] rescue false
    subjects = params[:subjects] rescue nil
    genres = params[:genres] rescue nil
    series = params[:series] rescue nil
    authors = params[:authors] rescue nil
    format_type = params[:format_type] rescue nil
    location_code = params[:location_code] rescue nil
    sort = params[:sort]  rescue nil
    shelving_location = params[:shelving_location] rescue nil
    if params[:page]
      page = (params[:page].to_i * 24) + params[:page].to_i 
    else
      page = 0
    end
    search_job = Searchjob.new
    if search_type == 'record'
      response = search_job.record(search_term)
    else
    response = search_job.get_results(search_term,
																			search_type,
																			format_type,
																			page,
																			available,
																			subjects,
																			genres,
																			series,
																			authors,
																			location_code,
                                      shelving_location,
                                      sort)
  	end
    respond_to do |format|
      format.html
      format.json {render json: response}
    end
  end

  def about
  end
end
