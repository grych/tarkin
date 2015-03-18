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

  # def password
  #   # sleep 1
  #   item = Item.find(params[:item].keys.first)
  #   if item
  #     t = get_token(cookies[:auth_token])
  #     current_user.authenticate t[:password]
  #     render text: item.password(authorization_user: current_user)
  #   else
  #     render text: 'unknown', status: 500
  #   end
  # end
end
