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
  after_initialize :generate_keys

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

end
