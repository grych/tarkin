require 'openssl'

def secure_token
  secret_file = Rails.root.join('.secret')
  if File.exist?(secret_file)
    return YAML::load_file(secret_file)
  else
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    key, iv = cipher.random_key, cipher.random_iv
    y = [key, iv]
    File.write(secret_file, y.to_yaml)
    return key, iv
  end
end

Rails.application.secrets.token_secret_key, Rails.application.secrets.token_secret_iv = secure_token 
