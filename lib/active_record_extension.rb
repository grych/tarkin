module ActiveRecordExtension
  extend ActiveSupport::Concern
  def encrypt(data, key, iv)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt
    cipher.key = key
    cipher.iv  = iv
    cipher.update(data) + cipher.final
  end

  def decrypt(data, key, iv)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.decrypt
    cipher.key = key
    cipher.iv  = iv
    cipher.update(data) + cipher.final
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtension)
