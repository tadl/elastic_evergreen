class MainController < ApplicationController
  def index
  	@record_count = Record.all.count
  end

  def about
  end
end
