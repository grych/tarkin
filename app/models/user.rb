# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  name                    :string(256)      not null
#  email                   :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class WrongPasswordException < Exception; end
class GroupNotAccessibleException < Exception; end

class User < ActiveRecord::Base
  has_many :group_meta_keys
  has_many :groups, through: :group_meta_keys

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


  ### 
  # Group Manipulation
  # must be done in context of user, because only authenticated user can decipher groups private_key

  # create and add new group
  # group must have at least one user, otherwise its private key can't be read
  # this method applies only to new groups
  def add_new_group(group)
    if group.new_record? and authenticated?
      @cipher.encrypt
      # generate key and iv to be used to encrypt the group private key
      @cipher.key = new_group_key = @cipher.random_key
      @cipher.iv = new_group_iv = @cipher.random_iv
      # cipher the group private key PEM with a new key and iv
      group.private_key_pem_crypted = @cipher.update(group.private_key_pem) + @cipher.final
      if group.save
        # store key and iv ciphered with my public key in association table
        meta = GroupMetaKey.new(user_id: self.id, group_id: group.id,
                                group_key_crypted: self.public_key.public_encrypt(new_group_key),
                                group_iv_crypted: self.public_key.public_encrypt(new_group_iv))
        meta.save!
      end
      group
    else
      raise GroupNotAccessibleException, "Group #{group.name} can't be accessed by #{self.name}"
    end
  end

  # add the other user to existing group
  # using his public key to store group key and iv
  def add_other_user_to_group(other, group)
    meta = self.group_meta_keys.find_by(group: group)
    if meta
      # decipher the group key and iv using my private key
      group_key = self.private_key.private_decrypt meta.group_key_crypted
      group_iv = self.private_key.private_decrypt meta.group_iv_crypted
      # save it with other user public key 
      meta = GroupMetaKey.new(user_id: other.id, group_id: group.id,
                              group_key_crypted: other.public_key.public_encrypt(group_key),
                              group_iv_crypted: other.public_key.public_encrypt(group_iv))
      meta.save!
    else
      raise GroupNotAccessibleException, "Group #{group.name} does not belongs to #{self.name}"
    end
  end

  # find the given group private key
  def group_private_key_pem(group)
    meta = self.group_meta_keys.find_by(group: group)
    if meta
      @cipher.decrypt
      @cipher.key = self.private_key.private_decrypt meta.group_key_crypted
      @cipher.iv = self.private_key.private_decrypt meta.group_iv_crypted
      @cipher.update(group.private_key_pem_crypted) + @cipher.final
    else
      raise GroupNotAccessibleException, "Group #{group.name} does not belongs to #{self.name}"
    end
  end
  def group_private_key(group)
    OpenSSL::PKey::RSA.new self.group_private_key_pem(group)
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
