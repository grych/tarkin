class DirectoriesController < ApplicationController
  before_action :signed_in_user

  def index
    @user = current_user
  end
end
