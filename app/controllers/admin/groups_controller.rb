class Admin::GroupsController < Admin::AdminController
  before_action :belongs_to_me, except: :index

  def index
    @groups = current_user.groups
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])
    @group.update_attributes group_params
    if @group.save
      redirect_to groups_path, notice: 'Group saved'
    else
      flash.now[:error] = "Group can't be saved, because #{@group.errors.full_messages.join(' and ')}"
      render 'edit'
    end
  end

  def destroy
    @group = Group.find(params[:id])
    if @group.destroy
      redirect_to groups_path, notice: 'Group deleted'
    else
      flash.now[:error] = "Group can't be deleted, because #{@group.errors.full_messages.join(' and ')}."
      render 'edit'
    end
  end

  private
  def group_params
    params.require(:group).permit(:name, :description)
  end

  def belongs_to_me
    g = Group.find(params[:id])
    redirect_to root_path, alert: "Group doesn't belong to you" unless current_user.groups.include? g
  end
end
