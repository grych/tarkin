class API::V1::SessionsController < Api::ApiController
  include SessionsHelper
  def create
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
      sign_in user
      render text: token_from_password(params[:password])
    else
      render text: 'Bad credentials', status: :unathorized
    end
  end
end
