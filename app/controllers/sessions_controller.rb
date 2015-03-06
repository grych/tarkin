class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      if Rails.env == 'production'
        cookies[:auth_token] = { value: token_from_password(params[:session][:password]), secure: true }
      else
        cookies[:auth_token] = { value: token_from_password(params[:session][:password]) }
      end
      sign_in user
      redirect_back_or root_url
    else
      flash.now[:error] = 'ACCESS DENIED!' 
      render :new
    end
  end

  def destroy
    sign_out
    #redirect_to root_url
  end
end
