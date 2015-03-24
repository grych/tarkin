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
