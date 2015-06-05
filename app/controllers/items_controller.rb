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
        format.js { render json: @item.errors.full_messages.uniq , status: :unprocessable_entity }
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
    # TODO: should modify only the users groups, not touch the others
    # @item.groups.delete(group)
    # @item.groups = []
    # groups.each do |group|
    #   @item.add group
    # end

    item_groups_previous = @item.groups.to_a
    errors = nil; error = false
    Item.transaction do 
      if groups.empty?
        errors = "can't be empty"
      else
        @item.update_attributes item_params
        groups_to_add = (groups - item_groups_previous) & current_user.groups
        logger.debug "***** to add: #{(groups_to_add)}"
        groups_to_add.each do |group|
          @item.add group
        end
        logger.debug "***** afer add: #{@item.groups.to_a}"
        unless @item.save
          error = true
          logger.debug "INSIDE *********** -------------------- #{errors}, error: #{error}"
          raise ActiveRecord::Rollback 
        else
          groups_to_destroy = (item_groups_previous - groups) & current_user.groups
          logger.debug "***** to destroy: #{groups_to_destroy}"
          @item.groups.destroy groups_to_destroy
          logger.debug "***** afer destroy: #{@item.groups.to_a}"
          if @item.groups.empty?
            errors = "can't be empty"
            raise ActiveRecord::Rollback 
          end
        end
      end
    end
    @item.errors[:groups] << errors if errors
    logger.debug "*********** -------------------- #{errors}, error: #{error}"
    respond_to do |format|
      if !error && errors.blank? && @item.save 
        format.js
      else
        format.js { render json: @item.errors.full_messages.uniq , status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item && @item.destroy
        format.js
      else
        format.js { render json: @item.errors.full_messages.uniq , status: :unprocessable_entity }
      end
    end
  end

  private
  def item_params
    params.require(:item).permit(:username, :password, :directory_id, :description).symbolize_keys
  end

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
  end
end
