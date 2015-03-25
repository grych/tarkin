# == User
# User represents the human operator. User have the RSA key pair, which is stored 
# in the database crypted by the users password. Password is not recoverable! - in case of 
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
#
# Users directories are the ones which belongs to the groups to which user belongs as well,
# #directories method will list them all, regardless of level (the flat list).
class User < ActiveRecord::Base
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys
  has_many :directories, through: :groups
  has_many :favorite_directories, through: :favorites, source: :directory 
  has_many :favorite_items,       through: :favorites, source: :item
  has_many :favorites, dependent: :destroy

  validates :name, presence: true, length: { maximum: 256 }
  validates :email, presence: true, length: { maximum: 256 }
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8, maximum: 32}

  before_save { email.downcase! }
  before_save :save_groups
  after_initialize :generate_keys

  # This is only for validators, password should never be readable
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

  # Returns user public key
  def public_key
    OpenSSL::PKey::RSA.new self.public_key_pem
  end

  # Returns user private key. It can be retrieved only when user is authenticated
  #   
  #   user = User.first
  #   user.password = 'password'
  #   user.private_key_pem.class    #=> String
  #   user.private_key.class        #=> OpenSSL::PKey::RSA
  def private_key_pem
    raise Tarkin::WrongPasswordException, "no password given for #{self.name}" if @password.nil?
    begin
      OpenSSL::PKey::RSA.new(self.private_key_pem_crypted, @password).to_pem
    rescue OpenSSL::PKey::RSAError, TypeError
      raise Tarkin::WrongPasswordException, "can't decrypt #{self.name}'s private key"
    end
  end
  def private_key
    OpenSSL::PKey::RSA.new self.private_key_pem
  end

  # Change User password. Re-crypt the private key using new password. After this,
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

  # Returns true when user is authenticated (correct password given)
  def authenticated?
    begin
      !self.private_key_pem.nil? && !new_record?
    rescue OpenSSL::Cipher::CipherError, Tarkin::WrongPasswordException
      false
    end
  end

  # Returns user if password is OK or nil in other case
  def authenticate(passwd)
  	self.password = passwd
  	if authenticated? then self else nil end
  end

  # Creates an association between +other+ object (Group or Item) and the current user.
  # In case of adding the group to the user, it could be either new group, or existing one - in the
  # second case there is a need to #authorize this operation with the user, which already belongs
  # to the group, as the group key must be read.
  #   
  #   User.first.add Group.new(name: 'new group')   # adding new group doesn't require authorization
  #
  # Adding existing group requires authorized user which belongs to this group:
  #
  #   other_user.add my_group, authorization_user: current_user
	def add(other, **options)
		authorizator = options[:authorization_user]
    @to_save = other
		case other
		when Group
			if other.new_record?
				other.add self
				other
			else
				raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authorizator and authorizator.authenticated?
				other.add self, authorization_user: authorizator
				other
			end
		end
	end

  # Set up user to perform next action with. See #<< operator
  def authorize(authorizor)
    raise Tarkin::NotAuthorized, "Did you mean 'authenticate'?" unless authorizor.is_a? User
    @authorization_user = authorizor
  end

  # Operator similar to #add method. Requires #authorize before:
  #
  #   user.authorize other_user
  #   other << item
  def <<(other)
    o = add(other, authorization_user: @authorization_user)
    other.save!
    self.save!
    o
  end

  # Returns array of items which belongs to this user, with intersection by Group
  def items
  	self.groups.map{|group| group.items}.flatten.uniq
  end

  # Returns the content (directory and items) of the given directory. Default is a root directory
  # (to which everyone has access). Directory must belong to one of the users group. Returns all
  # items and only the directories to which user has access.
  def ls(dir = Directory.root)
  	ls_dirs(dir) + ls_items(dir)
	end

	# Like #ls, but returns only directories
  def ls_dirs(dir = Directory.root)
		# self.directories & dir.directories
    dir.directories.where(id: self.directories.map{ |d| d.id }) #.order(:name)
	end

	# Like #ls, but returns only items
  def ls_items(dir = Directory.root)
		# self.items & dir.items
    dir.items.where(id: self.items.map{ |i| i.id }) #.order(:username)
	end

  # True, if the given Directory or Item is on the User shortlist. 
  def favorite?(thing)
    case thing
    when Directory
      self.favorite_directories.where(id: thing.id).exists?
    when Item
      self.favorite_items.where(id: thing.id).exists?
    else
      false
    end
  end

  # Shorter view
  def inspect
    "#<User> '#{self.name}'  [id: #{self.id}, email: #{self.email}]"
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

  def save_groups
    if @to_save
      @to_save.save! 
      @to_save.reload
    end 
    @to_save = nil
    true
  end
end
