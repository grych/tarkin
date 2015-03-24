class DirectoriesController < ApplicationController
  include DirectoriesHelper
  before_action :signed_in_user, except: :ok_with_cookies

  def index
    @new_directory = Directory.new
    @directory = Directory.root
  end

  def show
    @new_directory = Directory.new
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
      @directory.errors[:groups] << errors if errors
      respond_to do |format|
        if errors.blank? && @directory.save           
          format.js
        else
          format.js { render json: @directory.errors , status: :unprocessable_entity }
        end
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
end
