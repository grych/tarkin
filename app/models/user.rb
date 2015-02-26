# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  email                   :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  iv                      :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class PasswordNotExistsException < Exception; end

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 256 }
  validates :email, presence: true, length: { maximum: 256 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8, maximum: 32}

  before_save { email.downcase! }
  #after_initialize { @cipher ||= OpenSSL::Cipher::AES256.new(:CBC) }
  after_initialize :generate_keys

  def password
    '*' * @password.length if @password # only for validators, should not be visible
  end

  def password=(pwd)
    @password = pwd
    if new_record?
      generate_keys
    end
  end

  def public_key
    OpenSSL::PKey::RSA.new self.public_key_pem
  end

  def private_key_pem
    @cipher.decrypt
    @cipher.iv = self.iv
    @cipher.key = password_hash
    @cipher.update(self.private_key_pem_crypted) + @cipher.final
  end

  def private_key
    OpenSSL::PKey::RSA.new self.private_key_pem
  end

  def change_password(new_password)
    old_private_key_pem = self.private_key_pem
    @cipher.encrypt
    @cipher.iv = self.iv
    @password = new_password
    @cipher.key = password_hash
    self.private_key_pem_crypted = @cipher.update(old_private_key_pem) + @cipher.final
  end

  def authenticated?
    begin
      !self.private_key_pem.nil?
    rescue OpenSSL::Cipher::CipherError, PasswordNotExistsException
      false
    end
  end

  private
  def generate_keys
    @cipher ||= OpenSSL::Cipher::AES256.new(:CBC)
    if new_record? && @password # generate new keys only with new record with given password
      key = OpenSSL::PKey::RSA.new 2048 # key keeps the both keys
      self.public_key_pem = key.public_key.to_pem

      @cipher.encrypt
      self.iv = @cipher.random_iv   # iv is well known for this user, but random
      @cipher.iv = self.iv
      @cipher.key = password_hash
      self.private_key_pem_crypted = @cipher.update(key.to_pem) + @cipher.final   # store PEM for the generated key
    end
  end

  def password_hash
    raise PasswordNotExistsException, "Please specify a password for #{self.name}" unless @password
    OpenSSL::Digest::SHA256.digest @password
  end
end
