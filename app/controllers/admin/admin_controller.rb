class Admin::AdminController < ActionController::Base
  include SessionsHelper
  before_action :restrict_access
  layout 'application'
  
  private
  def restrict_access
    signed_in_user
    admin_user
  end
end
