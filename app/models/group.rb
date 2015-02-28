# == Schema Information
#
# Table name: groups
#
#  id                      :integer          not null, primary key
#  name                    :string(256)      not null
#  public_key_pem          :string(4096)     not null
#  private_key_pem_crypted :binary           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
require 'exceptions'
#
# <tt>Group</tt> associates <tt>User</tt> with <tt>Item</tt>. Must contain unique name and 
#  at least one user connected.
#  
#   group = Group.new name: 'group 1'
#   group.valid?  #=> false
#   group.errors.messages
#   => {:private_key_pem_crypted=>["can't be blank"], :group=>["'group 1' must contain at least one user"]}
#
# Key pair of the group generates during initialize. The private key of the group is saved 
# in <tt>MetaKey</tt> which belongs to the group and existing user.
class Group < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :users, through: :meta_keys
  has_many :items, through: :meta_keys

  validates :name, presence: true, length: { maximum: 256 }, uniqueness: { case_sensitive: false }
  validates :public_key_pem, presence: true
  validates :private_key_pem_crypted, presence: true
  validate  :have_users

  after_initialize :generate_keys
  before_destroy   :can_be_deleted

  # Public key and its PEM is always visible and accessible to any 
  def public_key
    OpenSSL::PKey::RSA.new self.public_key_pem
  end

  # The private key of the group can be accessed directly when it is a new group:
  #
  #   group = Group.new(name: 'group1')
  #   group.private_key   #=> #<OpenSSL::PKey::RSA:0x007faa65b33938>
  #  
  # Otherwise requires authorization user to be set in options[:authorization_user]. This user must
  # be valid and must belong to the group:
  # 
  #   group = Group.first
  #   group.private_key(authorization_user: user)
  #   #=> #<OpenSSL::PKey::RSA:0x007faa650db918>
  def private_key(**options)
    OpenSSL::PKey::RSA.new self.private_key_pem(**options)
  end

  # The private key PEM
  def private_key_pem(**options)
    authenticator = options[:authorization_user]
    raise Tarkin::PrivateKeyNotAccessibleException, 
      "Private key can't be accessed at this moment" if !new_record? && authenticator.nil? 
    if new_record?
      @private_key_pem
    else
      #cipher = OpenSSL::Cipher::AES256.new(:CBC)
      meta = authenticator.meta_keys.find_by(group: self)
      if meta
        # cipher.decrypt
        # cipher.key = authenticator.private_key.private_decrypt meta.key_crypted
        # cipher.iv = authenticator.private_key.private_decrypt meta.iv_crypted
        # cipher.update(self.private_key_pem_crypted) + cipher.final
        decrypt self.private_key_pem_crypted, authenticator.private_key.private_decrypt(meta.key_crypted),
                                               authenticator.private_key.private_decrypt(meta.iv_crypted)
      else
        raise Tarkin::GroupNotAccessibleException, "Group #{self.name} does not belongs to #{authenticator.name}"
      end
    end
  end

  # Associate +other+ object (<tt>User</tt> or <tt>Item</tt>) to group. 
  # Option <tt>authorized_by</tt> must be given unless adding the existing  
  # user to new group:
  #   
  #   group = Group.new(name: 'group 1')
  #   group.add user   # user must exist and be saved
  #
  # While adding user to the new group, it is being saved. Returns self, so can be chained.
  # Adding user to the group requires authorization:
  #
  #   group.add User.find_by(email: 'test@gdc.com'), authorization_user: user
  #
  # Association item with group must be done with autorization, as it requires group private 
  # key to be read. 
  #
  #   group.add Item.new(password: 'secret'), authorization_user: user
  def add(other, **options)
    authenticator = options[:authorization_user]
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    case other
    when User
      if new_record?
        # creating new group key
        if other.authenticated?
          # generate key and iv to be used to encrypt the group private key
          new_group_key, new_group_iv = cipher.random_key, cipher.random_iv
          # cipher the group private key PEM with a new key and iv
          self.private_key_pem_crypted = encrypt(self.private_key_pem, new_group_key, new_group_iv)
          self.users << other                               # add the user to the group
          meta = self.meta_keys.find {|x| x.user == other}  # can't use find_by or where, as it is not saved yet
                                                            # it should be a new record, so contains just one meta_key
          meta.key_crypted, meta.iv_crypted = other.public_key.public_encrypt(new_group_key), 
                                              other.public_key.public_encrypt(new_group_iv)
          self.save!
        else
          raise Tarkin::GroupNotAccessibleException, "Group #{self.name} can't be accessed by #{other.name}"
        end
      else
        raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authenticator
        meta = authenticator.meta_keys.find_by(group: self)
        if meta 
          # decipher the group key and iv using authorizing user private key
          group_key, group_iv = authenticator.private_key.private_decrypt(meta.key_crypted),
                                authenticator.private_key.private_decrypt(meta.iv_crypted)
          # save it with other user public key 
          meta = MetaKey.new(user: other, group: self,
                             key_crypted: other.public_key.public_encrypt(group_key),
                             iv_crypted: other.public_key.public_encrypt(group_iv)).save!
        else
          raise Tarkin::GroupNotAccessibleException, "Group #{self.name} does not belongs to #{authenticator.name}"
        end
        other
      end
    when Item
      raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authenticator.authenticated?
      # generate key and iv to be used to encrypt the item password
      new_item_key, new_item_iv = cipher.random_key, cipher.random_iv
      other.password_crypted = encrypt(other.password(authorization_user: authenticator), new_item_key, new_item_iv)
      key_crypted, iv_crypted = self.public_key.public_encrypt(new_item_key), self.public_key.public_encrypt(new_item_iv)
      if other.new_record?
        other.groups << self
        meta = other.meta_keys.find {|x| x.group == self}
        meta.key_crypted, meta.iv_crypted = key_crypted, iv_crypted
        other.save!
      else
        meta = MetaKey.new(group: self, item: other, key_crypted: key_crypted, iv_crypted:  iv_crypted)
        meta.save!
      end
      other
    end
  end

  private
  def generate_keys
    if new_record? 
      key = OpenSSL::PKey::RSA.new 2048 
      self.public_key_pem = key.public_key.to_pem
      @private_key_pem = key.to_pem 
    end
  end

  def have_users
    errors.add :group, "'#{self.name}' must contain at least one user" if self.users.empty?
  end

  def can_be_deleted
    # group can't be deleted if contains a link to at least one user or one item
    errors.add :group, "'#{self.name}' contains users" unless self.users.empty?
    errors.add :group, "'#{self.name}' contains items" unless self.items.empty?
    !(self.users.empty? || self.items.empty?)
  end
end
