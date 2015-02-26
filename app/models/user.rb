# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  email                   :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class WrongPasswordException < Exception; end

class User < ActiveRecord::Base
  validates :name, presence: true, length: { maximum: 256 }
  validates :email, presence: true, length: { maximum: 256 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8, maximum: 32}

  before_save { email.downcase! }
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
    raise WrongPasswordException, "no password for #{self.name}" if @password.nil?
    begin
      OpenSSL::PKey::RSA.new(self.private_key_pem_crypted, @password).to_pem
    rescue OpenSSL::PKey::RSAError, TypeError
      raise WrongPasswordException, "can't decrypt #{self.name} private key"
    end
  end

  def private_key
    OpenSSL::PKey::RSA.new self.private_key_pem
  end

  def change_password(new_password)
    old_private_key = self.private_key
    @password = new_password
    self.private_key_pem_crypted = old_private_key.to_pem @cipher, @password
  end

  def authenticated?
    begin
      !self.private_key_pem.nil? && !new_record?
    rescue OpenSSL::Cipher::CipherError, WrongPasswordException
      false
    end
  end

  private
  def generate_keys
    @cipher ||= OpenSSL::Cipher::AES256.new(:CBC)
    if new_record? && @password # generate new keys only with new record with given password
      key = OpenSSL::PKey::RSA.new 2048 # key keeps the both keys
      self.public_key_pem = key.public_key.to_pem
      self.private_key_pem_crypted = key.to_pem @cipher, @password
    end
  end

  def password_hash
    raise WrongPasswordException, "Please specify a password for #{self.name}" unless @password
    OpenSSL::Digest::SHA256.digest @password
  end
end
