class Api::ApiController < ActionController::Base
  include SessionsHelper
  before_action :restrict_access

  private
  def restrict_access
    unless restrict_access_by_header || restrict_access_by_params || restrict_access_by_http_authentication
      render json: 'Unathorized', status: :unathorized
    end
  end

  def restrict_access_by_header
    return true if @token
    authenticate_with_http_token do |token|
      t = get_token(token)
      sign_in_with_email_and_password User.find(t[:user_id]), t[:password]
    end
  end

  def restrict_access_by_params
    return true if @token
    if params[:email] && params[:password]
      email, password = [params[:email], params[:password]]
      logger.debug " ***** PARAMS #{email} #{password}"
      sign_in_with_email_and_password(email, password)
    end
  end

  def restrict_access_by_http_authentication
    return true if @token
    authenticate_or_request_with_http_basic("authenticate") do |email, password|
      logger.debug " ***** #{email} #{password}"
      sign_in_with_email_and_password(email, password)
    end
  end

  def sign_in_with_email_and_password(email, password)
    user = User.find_by(email: email)
    logger.debug " ***** #{email} #{password}"
    if user && user.authenticate(password)
      sign_in user
      @token = token_from_password(password)
      true
    else
      false
    end
  end
end
