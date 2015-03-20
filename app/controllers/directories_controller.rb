class DirectoriesController < ApplicationController
  before_action :signed_in_user, except: :ok_with_cookies

  def index
    @new_directory = Directory.new
    @directory = Directory.root
  end

  def show
    @new_directory = Directory.new
    @directory = Directory.cd(params[:path])
    @groups = @directory.groups
  end

  def create
    parent = Directory.find(params[:parent_id])
    @directory = parent.mkdir(directory_params[:name], description: directory_params[:description], groups: groups)
    respond_to do |format|
      if @directory.new_record? && @directory.save           
        format.js #{ render action: 'show', status: :created, location: @directory }
      else
        format.js { render json: @directory.errors , status: :unprocessable_entity }
      end
    end
  end

  def edit
    @directory=Directory.find(params[:id])
    @parent_directory = @directory.parent
    @groups = @directory.groups
    respond_to do |format|
      format.js
    end
  end

  def update
    @directory=Directory.find(params[:id])
    @directory.update_attributes directory_params
    @directory.groups = groups
    respond_to do |format|
      if @directory.save           
        format.js
      else
        format.js { render json: @directory.errors , status: :unprocessable_entity }
      end
    end
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

  private
  def directory_params
    params.require(:directory).permit(:name, :description)
  end

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
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
