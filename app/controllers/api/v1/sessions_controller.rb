class API::V1::SessionsController < Api::ApiController
  include SessionsHelper
  def create
    # email, password = [params[:email], password = params[:password]] if params[:email]
    # user = User.find_by(email: email)
    # if user && user.authenticate(password)
    #   sign_in user
    #   render text: token_from_password(password)
    # else
    #   render nothing: true, status: :unathorized
    # end
    #render json: 'dupa'
    render json: @token
  end
end
