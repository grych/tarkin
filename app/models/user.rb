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
# == User
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

  # This is only for validators, password should not be readable
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
				raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authenticator and authenticator.authenticated?
				other.add self, authorization_user: authenticator
				other
			end
		# when Item
		# 	meta, group = meta_and_group_for_item(other)
		# 	group.add other, authorization_user: self
		end
	end

  # Set up user to perform next action with. See +<<+ operator
  def authorize(authorizor)
    @authorization_user = authorizor
  end

  # Operator similar to +add+ method. Requires +authenticate+ before:
  #
  #   user.authorize other_user
  #   other << item
  def <<(other)
    add(other, authorization_user: @authorization_user)
  end

  # Returns array of items which belongs to this user, with intersection by +Group+
  def items
  	self.groups.map{|group| group.items}.flatten.uniq
  end

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
