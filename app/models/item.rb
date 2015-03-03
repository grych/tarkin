# == Item
# Item is the value encrypted and stored in the database. It contain password (I don't 
# want to call the class Password to avoid confusion between users password). 
class Item < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys
  belongs_to :directory
  validates :password_crypted, presence: true
  validate  :have_groups

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
    authenticator = options[:authorization_user]
    raise Tarkin::PasswordNotAccessibleException, "Password can't be accessed at this moment" if !new_record? && authenticator.nil? 
    if new_record? && @password
      @password
    else
      meta, group = meta_and_group_for_user authenticator
      decrypt self.password_crypted,
          group.private_key(authorization_user: authenticator).private_decrypt(meta.key_crypted),
          group.private_key(authorization_user: authenticator).private_decrypt(meta.iv_crypted)
    end
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
    raise Tarkin::ItemNotAccessibleException, "Group association not found for item #{self.id} and user #{user.id}" if groups.nil? || groups.empty? || groups.length != 1
    group = groups.first
    meta = self.meta_keys.find_by(group: group)
    raise Tarkin::ItemNotAccessibleException, "Item #{self.id} does not belong to #{group.name}" unless meta
    [meta, group]
  end
end
