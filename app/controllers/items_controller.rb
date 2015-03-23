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
    @item = Item.new(**item_params, directory_id: params[:directory_id])
    begin
      groups.each do |group|
        group.add @item, authorization_user: current_user
      end
    # TODO: rethink. Shouldn't be exceptions here...
    rescue Tarkin::MustSpecifyPasswordException => e
      
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
    params.require(:item).permit(:username).symbolize_keys
  end

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
  end
end