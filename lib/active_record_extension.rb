module ActiveRecordExtension
  extend ActiveSupport::Concern

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

ActiveRecord::Base.send(:include, ActiveRecordExtension)
