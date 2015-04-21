class Admin::GroupsController < Admin::AdminController
  def index
    @groups = Group.all
  end
end
