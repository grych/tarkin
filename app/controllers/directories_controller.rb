class DirectoriesController < ApplicationController
  include DirectoriesHelper
  before_action :signed_in_user, except: :ok_with_cookies

  def index
    @new_directory = Directory.new
    @directory = Directory.root
  end

  def show
    # @new_directory = Directory.new
    @directory = Directory.cd(path_from_url(params[:path]))
    @groups = @directory.groups
  end

  def new
    @directory=Directory.new
    @parent_directory = Directory.find(params[:parent_id])
    @groups = @parent_directory.groups # user: current_user
    respond_to do |format|
      format.js
    end
  end

  def create
    parent = Directory.find(params[:parent_id])
    @directory = parent.mkdir(directory_params[:name], groups: groups, **directory_params.symbolize_keys.except(:name))
    respond_to do |format|
      if @directory.new_record? && @directory.save           
        format.js 
      else
        format.js { render json: @directory.errors.full_messages.uniq , status: :unprocessable_entity }
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
    errors = nil
    directory_groups_previous = @directory.groups.to_a
    @directory.transaction do 
      if groups.empty?
        errors = "can't be empty"
      else
        @directory.update_attributes directory_params
        # update group list for directory
        groups_to_add = (groups - directory_groups_previous) & current_user.groups
        groups_to_add.each do |group|
          @directory.groups << group
        end
        groups_to_destroy = (directory_groups_previous - groups) & current_user.groups
        @directory.groups.destroy groups_to_destroy
        if @directory.groups.empty?
          errors = "can't be empty"
          raise ActiveRecord::Rollback 
        end
      end
    end
    @directory.errors[:groups] << errors if errors
    respond_to do |format|
      if errors.blank? && @directory.save           
        format.js
      else
        format.js { render json: @directory.errors.full_messages.uniq , status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @directory = Directory.find(params[:id])
    respond_to do |format|
      if @directory && @directory.destroy
        format.js
      else
        format.js { render json: @directory.errors.full_messages.uniq, status: :unprocessable_entity }
      end
    end
  end

  def search
    @items = current_user.search_items(params[:term]).order(:username)
    @directories = current_user.search_dirs_names(params[:term]).order(:name)
  end

  # User profile (name, email, etc)
  def profile
    @user = current_user
  end
  def update_profile
    @user = current_user
    @user.update_attributes user_params
    respond_to do |format|
      if @user.save
        # format.js { render partial: 'updated_profile'}
        format.js {render inline: "location.reload();" }
      else
        format.js { render json: @user.errors.full_messages.uniq, status: :unprocessable_entity }
      end    
    end
  end

  # Current user password
  def password
    @user = current_user
  end
  def update_password
    if user_params[:password] == user_params[:password_confirmation]
      @user = current_user
      @user.change_password user_params[:password]
      respond_to do |format|
        if @user.save
          if @user.authenticate(user_params[:password])
            sign_in @user
            if Rails.env == 'production'
              cookies[:auth_token] = { value: token_from_password(user_params[:password]), secure: true }
            else
              cookies[:auth_token] = { value: token_from_password(user_params[:password]) }
            end
            format.js { render inline: "$('#edit-modal').foundation('reveal', 'close')" }
          else
            format.js { render json: ["Password has been changed, but something went wrong. Please login again"], status: :unprocessable_entity }
          end
        else
          format.js { render json: @user.errors.full_messages.uniq, status: :unprocessable_entity }
        end    
      end
    else
      respond_to {|format| format.js {render json: ["Passwords don't match"], status: :unprocessable_entity }}
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
      render json: {ok: true}
    when 'dir'
      d = Directory.find(params[:id])
      if current_user.favorite? d
        current_user.favorite_directories.destroy d
      else
        current_user.favorite_directories << d
      end
      render json: {ok: true, html: render_to_string(partial: 'favorites')}
    else
      render json: {ok: false}
    end
  end

  private
  def directory_params
    params.require(:directory).permit(:name, :description)
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
  end
end
