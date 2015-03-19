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

  def switch_favorite
    logger.debug "switch_favorite, params: #{params}"
    case params[:type]
    when 'item'
      i = Item.find(params[:id])
      if current_user.favorite? i
        current_user.favorite_items.destroy i
      else
        current_user.favorite_items << i
      end
    when 'dir'
      d = Directory.find(params[:id])
      if current_user.favorite? d
        current_user.favorite_directories.destroy d
      else
        current_user.favorite_directories << d
      end
    end
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
