module SessionsHelper
  def sign_in(user)
    # I don't want to keep the whole user object in session, because password is a property of it
    session[:current_user_id] = user.id
    self.current_user = user
  end

  def sign_out
    @current_user_id =  nil
    session.delete(:current_user_id)
  end

  def current_user=(user)
    @current_user_id = user.id
    @current_user = user
  end

  def current_user
    @current_user_id ||= session[:current_user_id]
    begin
      @current_user ||= User.find(@current_user_id) if @current_user_id
    rescue ActiveRecord::RecordNotFound
      return nil
    end
    @current_user
  end

  def signed_in?
    # current user must not be nil and token must be valid
    !current_user.nil? && valid_token?(cookies[:auth_token])
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    session[:return_to] = request.url if request.get?
  end

  def current_user?(user)
    user == current_user
  end

  # controller callbacks
  def signed_in_user
    unless signed_in?
      store_location
      redirect_to new_session_path #, notice: "Please sign in."
    end
  end

  def admin_user
    unless current_user.try(:admin?)
      store_location
      redirect_to(root_url, alert: "You must have admin rights to do this.") 
    end
  end

  def salt
    #len = if Rails.env == 'production' then 128 else 32 end
    #@salt ||= SecureRandom.hex(rand(16..128))
    @salt ||= SecureRandom.hex(128)
  end

  def token_from_password(password)
    token = {created_at: Time.now, 
               password: password, 
                  agent: request.env['HTTP_USER_AGENT'],
                user_id: current_user.id }
    Base64.urlsafe_encode64 encrypt(salt + token.to_yaml, Rails.application.secrets.token_secret_key, Rails.application.secrets.token_secret_iv)
  end

  # decrypts token from given encrypted one 
  def get_token(token)
    begin
      t = decrypt(Base64.urlsafe_decode64(token), Rails.application.secrets.token_secret_key, Rails.application.secrets.token_secret_iv)
    rescue ArgumentError # invalid base 64
      return nil
    end
    y = YAML.load(t[salt.length..-1])
    user = User.find(y[:user_id])
    if !(user.token_expires_in.blank? || user.token_expires_in <= 0) && (Time.now - y[:created_at]).to_i / 1.day > user.token_expires_in
      nil 
    else
      y
    end
  end

  def valid_token?(token)
    t = get_token(token) if token
    # token must exists, user must authenticate with it and user agent must not be changed
    token && t && current_user.authenticate(t[:password]) && t[:agent] == request.env['HTTP_USER_AGENT'] 
    rescue OpenSSL::Cipher::CipherError
      return false
    rescue ArgumentError # bad base64 encode
      return false
  end

  # Returns binary data encrypted with AES-256-CBC
  def encrypt(data, key, iv)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt
    cipher.key = key
    cipher.iv  = iv
    cipher.update(data) + cipher.final
  end

  # Returns data decrypted with AES-256-CBC
  def decrypt(data, key, iv)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.decrypt
    cipher.key = key
    cipher.iv  = iv
    cipher.update(data) + cipher.final
  end

end
