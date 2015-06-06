class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      sign_in user
      if Rails.env == 'production'
        # TODO: it is temporary disabled, as Demo is running not on SSL
        # cookies[:auth_token] = { value: token_from_password(params[:session][:password]), secure: true }
        cookies[:auth_token] = { value: token_from_password(params[:session][:password]) }
      else
        cookies[:auth_token] = { value: token_from_password(params[:session][:password]) }
      end
      redirect_back_or root_url
    else
      flash.now[:error] = 'ACCESS DENIED!' 
      render :new
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
