class DirectoriesController < ApplicationController
  before_action :signed_in_user, except: :ok_with_cookies

  def index
    @directory = Directory.root
  end

  def show
    @directory = Directory.cd(params[:path])
  end

  # AJAX
  def ok_with_cookies
    session[:ok_with_cookies] = true
    render json: {ok: true}
  end
end
