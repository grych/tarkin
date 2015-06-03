class Admin::AdminController < ActionController::Base
  include SessionsHelper
  before_action :restrict_access
  layout 'admin'
  
  private
  def restrict_access
    signed_in_user
    # unless controller_name = 'users' && action_name = 'edit' && current_user.id == params[:id].to_i
    admin_user 
    # end
  end
end
