class DirectoriesController < ApplicationController
  before_action :signed_in_user

  def index
    @directory = Directory.root
  end

  def show
    @directory = Directory.cd(params[:path])
  end
end
