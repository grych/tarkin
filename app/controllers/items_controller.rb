class ItemsController < ApplicationController
  before_action :signed_in_user

  def new
    @item=Item.new
    @directory=Directory.find(params[:parent_id])
    @groups = @directory.groups 
    respond_to do |format|
      format.js
      format.html { render partial: 'form', locals: {modal: false, directory: @directory, item: @item, groups: @groups, action: :create } }
    end
  end

  def create
    # directory = Directory.find(params[:directory_id])
    @item = Item.new(**item_params)
    groups.each do |group|
      @item.add group, authorization_user: current_user
    end
    respond_to do |format|
      if @item.new_record? && @item.save
        format.js
      else
        format.js { render json: @item.errors , status: :unprocessable_entity }
      end
    end    
  end

  def edit
    @item = Item.find(params[:id])
    @item.authorize current_user
    @directory = @item.directory
    @groups = @item.groups
    respond_to do |format|
      format.js
    end
  end

  def update
    @item = Item.find(params[:id])
    @item.authorize current_user
    @item.update_attributes item_params
    # TODO: should modify only the users groups, not touch the others
    # @item.groups.delete(group)
    # @item.groups = []
    # groups.each do |group|
    #   @item.add group
    # end
    item_groups_previous = @item.groups.to_a
    errors = nil
    Item.transaction do 
      logger.debug "***** to add: #{(groups - item_groups_previous)}"
      (groups - item_groups_previous).each do |group|
        @item.add group
      end
      logger.debug "***** afer add: #{@item.groups.to_a}"
      logger.debug "***** to destroy: #{(item_groups_previous - groups)}"
      @item.groups.destroy(item_groups_previous - groups)
      logger.debug "***** afer destroy: #{@item.groups.to_a}"
      if @item.groups.empty?
        errors = "can't be empty"
        raise ActiveRecord::Rollback 
      end
    end
    @item.errors[:groups] << errors if errors
    respond_to do |format|
      if @item.save           
        format.js
      else
        format.js { render json: @item.errors , status: :unprocessable_entity }
      end
    end
  end

  private
  def item_params
    params.require(:item).permit(:username, :password, :directory_id).symbolize_keys
  end

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
  end
end
