class Admin::UsersController < Admin::AdminController
  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])
    @groups = @user.groups
  end

  def update
    @user = User.find(params[:id])
    errors = nil
    user_groups_previous = @user.groups.to_a
    if groups.empty?  
      errors = "can't be empty"
    else    
      @user.update_attributes user_params
      if @user.save
        # update group list for user
        groups_to_add = (groups - user_groups_previous) & current_user.groups
        groups_to_add.each do |group|
          @user.add group, authorization_user: current_user
        end
        groups_to_destroy = (user_groups_previous - groups) & current_user.groups
        @user.groups.destroy groups_to_destroy
        @user.save
        if @user.groups.empty?
          errors = "list can't be empty"
        end
      end
    end
    @groups = @user.groups
    if errors.blank? && @user.valid?
      redirect_to users_path
    else
      @user.errors[:groups] << errors if errors
      flash.now[:error] = "User can't be updated, because #{@user.errors.full_messages.join(' and ')}"
      render 'edit'
    end
  end

  def new
    @user = User.new
    @groups = current_user.groups
  end

  def create
    @user = User.new(user_params)
    @groups = groups
    if user_params[:password] == params[:user][:password_confirmation]
      current_user.add @user
      if @user.save
        @user.authorize current_user
        @groups.each { |group| @user << group }
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
      flash.now[:error] = "Suicide's bad, mkey?"
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

  def groups
    if params[:groups].try(:map)
      params[:groups].map{ |group_id, _| Group.find(group_id) } 
    else 
      [] 
    end
  end

end
