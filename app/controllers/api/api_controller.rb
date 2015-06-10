# API for external applications and for the webpage. All API calls are restricted and must
# be authorized by username/password combination or authorization token. See API::V1::SessionsController#create
# to find out how to retrieve the token.
#
# authorization methods::
# * auth token in header: <tt>Authorization: Token token=$TOKEN</tt> or
# * cookie "auth_token" set, or
# * User email and password as GET/POST parameters, or
# * basic http authentication in header
class Api::ApiController < ActionController::Base
  include SessionsHelper
  before_action :restrict_access

  private
  def restrict_access
    # puts "***** RESTRIC #{restrict_access_by_header || restrict_access_by_cookie || restrict_access_by_http_authentication || restrict_access_by_params}"
    unless  restrict_access_by_header || restrict_access_by_cookie || restrict_access_by_http_authentication || restrict_access_by_params
      # render json: 'Unathorized', status: :unathorized
      head 401
    end
  end

  def restrict_access_by_header
    return true if @token
    puts "header"
    authenticate_with_http_token do |token, options|
      t = get_token(token)
      puts token
      logger.debug " ************* HEADER #{t[:user_id]} #{t[:password]}" if t
      sign_in_with_email_and_password(User.find(t[:user_id]).email, t[:password]) if t
      # logger.debug " **** password: #{t[:password]}"
    end
  end

  def restrict_access_by_cookie
    # puts "cookie"
    return true if @token
    if cookies[:auth_token]
      t = get_token(cookies[:auth_token])
      logger.debug " ************* COOKIE #{t[:user_id]} #{t[:password]}" if t
      sign_in_with_email_and_password(User.find(t[:user_id]).email, t[:password]) if t
      # logger.debug " **** password: #{t[:password]}"
    else
      false
    end
  end

  def restrict_access_by_params
    # puts "params"
    return true if @token
    if params[:email] && params[:password]
      email, password = [params[:email], params[:password]]
      logger.debug " ***** PARAMS #{email} #{password}"
      # puts " ***** PARAMS #{email} #{password}"
      sign_in_with_email_and_password(email, password)
    end
  end

  def restrict_access_by_http_authentication
    # puts "http"
    return true if @token
    authenticate_with_http_basic do |email, password|
      logger.debug " ***** HTTP #{email} #{password}"
      sign_in_with_email_and_password(email, password)
    end
  end

  def sign_in_with_email_and_password(email, password)
    user = User.find_by(email: email)
    logger.debug " ***** SIGN IN: #{email} #{password}"
    if user && user.authenticate(password)
      sign_in user
      logger.debug " ============ #{current_user.authenticated?}"
      @token = token_from_password(password)
      true
    else
      false
    end
  end
end
