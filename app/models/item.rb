# == Item
# Item is the value encrypted and stored in the database. It contain password (I don't 
# want to call the class Password to avoid confusion between users password). 
class Item < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys
  belongs_to :directory

  # validates :password_crypted, presence: true
  validates :password, presence: true
  validates :username, presence: true
  validate  :have_groups

  after_save :reload_groups

  # default_scope { order('username ASC') }

  # Set up user to perform next action with. See +<<+ operator
  def authorize(authorizor)
    @authorization_user = authorizor
  end

  # Set the password. With new record, just set the instance value, with the existing one - must
  # decrypt and encrypt again. With existing item, must be authenticated
  #
  #   item.authorize user
  #   item.password = 'new password'
  #   item.save!
  def password=(pwd)
    if new_record?
      @password = pwd 
    else
      set_password pwd, authorization_user: @authorization_user
    end
  end

  # Set the password, using the given user. Similar to +password=+ operator.
  #
  #   item.set_password "new password", authorization_user: user
  def set_password(new_password, **options)
    authenticator = options[:authorization_user]
    raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authenticator && authenticator.authenticated?
    @password = new_password
    meta, group = meta_and_group_for_user authenticator
    self.password_crypted = encrypt new_password,
      group.private_key(authorization_user: authenticator).private_decrypt(meta.key_crypted),
      group.private_key(authorization_user: authenticator).private_decrypt(meta.iv_crypted)
  end

  # Returns the opentext password. Must be authorized by User which have the same group like Item
  #
  #   plaintext = item.password(authorization_user: user)
  def password(**options)
    authenticator = options[:authorization_user] || @authorization_user
    # raise Tarkin::PasswordNotAccessibleException, "Password can't be accessed at this moment" if !new_record? && authenticator.nil? 
    return "********" if !new_record? && authenticator.nil? # for validator
    if new_record? && @password
      @password.force_encoding('utf-8')
    else
      if authenticator
        begin
          meta, group = meta_and_group_for_user authenticator
        rescue Tarkin::ItemNotAccessibleException
          self.errors[:password] << "can't be decrypted"
          return "********"
        end
        decrypt(self.password_crypted,
            group.private_key(authorization_user: authenticator).private_decrypt(meta.key_crypted),
            group.private_key(authorization_user: authenticator).private_decrypt(meta.iv_crypted)).force_encoding( 'utf-8' )
      else
        self.errors[:password] << "can't be empty"
        "********"
      end
    end
  end

  # Associate +other+ object with the item. 
  #
  #   i = Item.new(username:'u', password:'p'); g=Group.first; u=User.first; u.password='password0'
  #   i.add g
  #   #=> #<Group:0x007fbbef4187e8>
  def add(other, **options)
    authenticator = options[:authorization_user] || @authorization_user
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    case other
    when Group
      if self.new_record? && self.groups.empty?
        # user not needed
        new_item_key, new_item_iv = cipher.random_key, cipher.random_iv
        key_crypted, iv_crypted = other.public_key.public_encrypt(new_item_key), other.public_key.public_encrypt(new_item_iv)
        self.password_crypted = encrypt(self.password, new_item_key, new_item_iv)
        self.groups << other
        meta = self.meta_keys.find {|x| x.group == other}
        raise "Couldn't find the corresponding meta" unless meta
        meta.key_crypted, meta.iv_crypted = key_crypted, iv_crypted
      else
        # have to decrypt
        raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless authenticator
        authenticator_meta, authenticator_group = meta_and_group_for_user authenticator
        # puts "*** #{authenticator_meta.id} #{authenticator_group.id}"
        authenticator_group_private_key = authenticator_group.private_key(authorization_user: authenticator)
        item_key, item_iv = authenticator_group_private_key.private_decrypt(authenticator_meta.key_crypted),
                            authenticator_group_private_key.private_decrypt(authenticator_meta.iv_crypted)
        key_crypted, iv_crypted = other.public_key.public_encrypt(item_key), other.public_key.public_encrypt(item_iv)
        self.meta_keys.new group: other, key_crypted: key_crypted, iv_crypted: iv_crypted
        @must_reload = true # must reload after save to see the new added group
        # self.items(true)
        # other.groups(true)
      end
      other
    end
  end

  # Operator similar to #add method. Requires #authorize before. Saves +self+ before exit.
  #
  #   item.authorize user
  #   item << Group.first
  def <<(other)
    raise Tarkin::NotAuthorized, "This operation must be autorized by valid user" unless @authorization_user
    o = add(other, authorization_user: @authorization_user)
    self.save!
    o.save!
    o
  end

  # Shorter view - to prevent rails console to show all the encrypted data
  def inspect
    "#<Item> '#{self.username}'  [id: #{self.id}, directory_id: #{self.directory_id}]"
  end

  private
  # Validator: item must be associated with at least one group
  def have_groups
    errors.add :item, "must belong at least to one group" if self.groups.empty?
  end

  # Find the meta and group from association between group and item
  # as the intersections between two group arrays
  def meta_and_group_for_user(user)
    groups = user.groups & self.groups
    # puts "user #{user.id} groups #{user.groups.map{|x| x.id}}"
    # puts "item #{self.id} groups #{self.groups.map{|x| x.id}}"
    # puts "#{groups}"
    raise Tarkin::ItemNotAccessibleException, "Group association not found for item #{self.username} and user #{user.name}" if groups.nil? || groups.empty? 
    group = groups.first
    # meta = self.meta_keys.find_by(group: group)
    meta = self.meta_keys.find {|x| x.group == group}
    raise Tarkin::ItemNotAccessibleException, "Item #{self.id} does not belong to #{group.name}" unless meta
    [meta, group]
  end

  def meta_and_group_for_user_and_item(user, item)
    groups = user.groups & item.groups
    raise Tarkin::ItemNotAccessibleException, "Group association not found for item #{item.username} and user #{user.name}" if groups.nil? || groups.empty? 
    group = groups.first
    # meta = item.meta_keys.find_by(group: group)
    meta = item.meta_keys.find {|x| x.group == group}
    raise Tarkin::ItemNotAccessibleException, "Item #{self.id} does not belong to #{group.name}" unless meta
    [meta, group]
  end

  def reload_groups
    if @must_reload
      self.reload
      @must_reload = false
    end
    true
  end
end
