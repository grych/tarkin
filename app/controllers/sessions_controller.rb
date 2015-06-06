class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      sign_in user
      if Rails.env == 'production'
        if ENV['TARKIN_DEMO']
          cookies[:auth_token] = { value: token_from_password(params[:session][:password]) }
        else
          cookies[:auth_token] = { value: token_from_password(params[:session][:password]), secure: true }
        end
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
