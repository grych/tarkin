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

class PrivateKeyNotAccessibleException < Exception; end

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

  def public_key
    OpenSSL::PKey::RSA.new self.public_key_pem
  end

  def private_key(user=nil)
    OpenSSL::PKey::RSA.new self.private_key_pem(user)
  end

  def private_key_pem(user=nil)
    raise PrivateKeyNotAccessibleException, "Private key can't be accessed at this moment" if !new_record? && user.nil? 
    if new_record?
      @private_key_pem
    else
      user.group_private_key_pem(self)
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
