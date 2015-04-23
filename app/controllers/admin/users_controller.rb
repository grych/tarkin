class Admin::UsersController < Admin::AdminController
  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update_attributes user_params
    if @user.save
      redirect_to users_path #, notice: 'User saved'
    else
      flash.now[:error] = "User can't be saved, because #{@user.errors.full_messages.join(' and ')}"
      render 'edit'
    end    
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if user_params[:password] == params[:user][:password_confirmation]
      current_user.add @user
      if @user.save
        redirect_to users_path #, notice: 'User created'
      else
        flash.now[:error] = "User can't be created, because #{@user.errors.full_messages.join(' and ')}"
        render 'new'
      end
    else
      flash.now[:error] = "Passwords doesn't match"
      render 'new'
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user == current_user
      flash.now[:error] = "Suicide denied"
      render 'edit'
    else
      if @user.destroy
        redirect_to users_path #, notice: 'user deleted'
      else
        flash.now[:error] = "User can't be deleted, because #{@user.errors.full_messages.join(' and ')}."
        render 'edit'
      end
    end
  end

  private
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :admin, :token_expires_in, :password)
  end

end
