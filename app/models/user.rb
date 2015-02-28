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
require 'exceptions'
#
# <tt>User</tt> represents the human operator. User have the RSA key pair, which is stored 
# in the database crypted by the users password. +Password is not recoverable!+ - in case of 
# lost the only way is to regenerate the users keys and rejoin the user to groups.
#
# All operations on private keys, groups, items requires authorization - the given password. 
# Newly created user is not considered authenticated until +save+ (to be valid)
#
#   user = User.new(name: 'User', email: 'email@example.com', password: 'password')
#   user.authenticated?  #=> false
#   user.save
#   user.authenticated?  #=> true
#
# Loaded user is authenticated only if the password is given:
#   user = User.last
#   user.authenticated?      #=> false
#   user.password = 'password'
#   user.authenticated?      #=> true
#   user.private_key.class   #=> OpenSSL::PKey::RSA
class User < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys

  validates :name, presence: true, length: { maximum: 256 }
  validates :email, presence: true, length: { maximum: 256 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8, maximum: 32}

  before_save { email.downcase! }
  after_initialize :generate_keys

  # This is only for validators, should not be visible
  def password
    '*' * @password.length if @password 
  end

  # User authentication requires password
  def password=(pwd)
    @password = pwd
    if new_record?
      generate_keys
    end
  end

  # Public key and its PEM is visible to all 
  def public_key
    OpenSSL::PKey::RSA.new self.public_key_pem
  end

  # private key can be retrieved only when user is authenticated
  #   
  #   user = User.first
  #   user.password = 'password'
  #   user.private_key_pem.class    #=> String
  #   user.private_key.class        #=> OpenSSL::PKey::RSA
  def private_key_pem
    raise Tarkin::WrongPasswordException, "no password for #{self.name}" if @password.nil?
    begin
      OpenSSL::PKey::RSA.new(self.private_key_pem_crypted, @password).to_pem
    rescue OpenSSL::PKey::RSAError, TypeError
      raise Tarkin::WrongPasswordException, "can't decrypt #{self.name} private key"
    end
  end
  def private_key
    OpenSSL::PKey::RSA.new self.private_key_pem
  end

  # Change user password. Re-crypt the private key using new password. After this,
  # user is still authenticated and can retrieve a private key
  #
  #   user = User.first
  #   user.password = 'password'
  #   user.change_password('new password')
  #   user.private_key.class                #=> OpenSSL::PKey::RSA
  def change_password(new_password)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    old_private_key = self.private_key
    @password = new_password
    self.private_key_pem_crypted = old_private_key.to_pem cipher, @password
  end

  # True if password is given and can decrypt the private key
  def authenticated?
    begin
      !self.private_key_pem.nil? && !new_record?
    rescue OpenSSL::Cipher::CipherError, Tarkin::WrongPasswordException
      false
    end
  end

  # Creates an association between +other+ object (<tt>Group</tt>, <tt>Item</tt>) and the current user.
  # In case of adding the group to the user, it could be either new group, or existing one - in the
  # second case there is a need to authorize this operation with the user, which already belongs
  # to the group, as the group key must be read.
  #   
  #   User.first.add Group.new(name: 'new group')   # adding new group doesn't require authorization
  #
  # Adding existing group requires authorized user which belongs to this group:
  #
  #   other_user.add my_group, authorization_user: current_user
	def add(other, **options)
		authenticator = options[:authorization_user]
		case other
		when Group
			if other.new_record?
				other.add self
				other
			else
				other.add self, authorization_user: authenticator
				other
			end
		end
	end

  # ### 
  # # Group Manipulation
  # # must be done in context of user, because only authenticated user can decipher groups private_key

  # # create and add new group
  # # group must have at least one user, otherwise its private key can't be read
  # # this method applies only to new groups
  # def obsolete_add_new_group(group)
  #   cipher = OpenSSL::Cipher::AES256.new(:CBC)
  #   if group.new_record? and authenticated?
  #     cipher.encrypt
  #     # generate key and iv to be used to encrypt the group private key
  #     cipher.key = new_group_key = cipher.random_key
  #     cipher.iv = new_group_iv = cipher.random_iv
  #     # cipher the group private key PEM with a new key and iv
  #     group.private_key_pem_crypted = cipher.update(group.private_key_pem) + cipher.final
  #     group.users << self # add user to the group
  #     meta = group.meta_keys.find {|x| x.user == self}  # can't use find_by or where, as it is not saved yet
  #                                                       # it should be a new record, so contains just one meta_key
  #     meta.key_crypted = self.public_key.public_encrypt(new_group_key)
  #     meta.iv_crypted = self.public_key.public_encrypt(new_group_iv)
  #     group.save
  #     group
  #   else
  #     raise Tarkin::GroupNotAccessibleException, "Group #{group.name} can't be accessed by #{self.name}"
  #   end
  # end

  # # add the other user to existing group
  # # using his public key to store group key and iv
  # def obsolete_add_other_user_to_group(other, group)
  #   cipher = OpenSSL::Cipher::AES256.new(:CBC)
  #   meta = self.meta_keys.find_by(group: group)
  #   if meta
  #     # decipher the group key and iv using my private key
  #     group_key = self.private_key.private_decrypt meta.key_crypted
  #     group_iv = self.private_key.private_decrypt meta.iv_crypted
  #     # save it with other user public key 
  #     meta = MetaKey.new(user_id: other.id, group_id: group.id,
  #                             key_crypted: other.public_key.public_encrypt(group_key),
  #                             iv_crypted: other.public_key.public_encrypt(group_iv))
  #     meta.save!
  #   else
  #     raise Tarkin::GroupNotAccessibleException, "Group #{group.name} does not belongs to #{self.name}"
  #   end
  # end

  # # find the given group private key
  # def obsolete_group_private_key_pem(group)
  #   cipher = OpenSSL::Cipher::AES256.new(:CBC)
  #   meta = self.meta_keys.find_by(group: group)
  #   if meta
  #     cipher.decrypt
  #     cipher.key = self.private_key.private_decrypt meta.key_crypted
  #     cipher.iv = self.private_key.private_decrypt meta.iv_crypted
  #     cipher.update(group.private_key_pem_crypted) + cipher.final
  #   else
  #     raise Tarkin::GroupNotAccessibleException, "Group #{group.name} does not belongs to #{self.name}"
  #   end
  # end
  # def group_private_key(group)
  #   OpenSSL::PKey::RSA.new self.group_private_key_pem(group)
  # end

  # ###
  # # Manipulate items
  
  # # add new item (password) to the group in context of user (self)
  # def obsolete_add_new_item(group, item)
  #   cipher = OpenSSL::Cipher::AES256.new(:CBC)
  #   if item.new_record? and authenticated?
  #     cipher.encrypt
  #     # generate key and iv to be used to encrypt the item password
  #     cipher.key = new_item_key = cipher.random_key
  #     cipher.iv = new_item_iv = cipher.random_iv
  #     # cipher the password with a new key and iv
  #     item.password_crypted = cipher.update(item.password) + cipher.final
  #     item.groups << group
  #     meta = item.meta_keys.find {|x| x.group == group}
  #     meta.key_crypted = group.public_key.public_encrypt(new_item_key)
  #     meta.iv_crypted = group.public_key.public_encrypt(new_item_iv)
  #     item.save
  #     item
  #   else
  #     raise Tarkin::GroupNotAccessibleException, "Group #{group.name} can't be accessed by #{self.name}"
  #   end
  # end

  # def obsolete_add_other_item_to_group(group, item)
  # end

  # # decrypt the password for item using group private key
  # def obsolete_item_password(item)
  #   cipher = OpenSSL::Cipher::AES256.new(:CBC)
  #   # find the group from association between group and item
  #   # as the intersections between two group arrays
  #   groups = self.groups & item.groups
  #   raise ItemNotAccessibleException, "Groups intersection couldn't be find for item #{item.id} and group #{group.id}" if groups.nil? || groups.empty? || groups.length != 1
  #   group = groups.first
  #   #meta = group.meta_keys.find_by(item: item)
  #   meta = item.meta_keys.find_by(group: group)
  #   if meta
  #     cipher.decrypt
  #     cipher.key = group.private_key(self).private_decrypt(meta.key_crypted)
  #     cipher.iv = group.private_key(self).private_decrypt(meta.iv_crypted)
  #     cipher.update(item.password_crypted) + cipher.final
  #   else
  #     raise Tarkin::ItemNotAccessibleException, "Item #{item.id} does not belongs to #{group.name}"
  #   end
  # end

  private
  def generate_keys
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    if new_record? && @password # generate new keys only with new record with given password
      key = OpenSSL::PKey::RSA.new 2048 # key keeps the both keys
      self.public_key_pem = key.public_key.to_pem
      self.private_key_pem_crypted = key.to_pem cipher, @password
    end
  end

  def password_hash
    raise Tarkin::WrongPasswordException, "Please specify a password for #{self.name}" unless @password
    OpenSSL::Digest::SHA256.digest @password
  end
end
