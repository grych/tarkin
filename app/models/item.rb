# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  password_crypted :binary
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'exceptions'

class Item < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys
  validates :password_crypted, presence: true
  validate  :have_groups

  def password=(pwd)
    @password = pwd if new_record?
  end

  def password(**options)
    authenticator = options[:authorization_user]
    raise Tarkin::PasswordNotAccessibleException, "Password can't be accessed at this moment" if !new_record? && authenticator.nil? 
    if new_record?
      @password
    else
      # find the group from association between group and item
      # as the intersections between two group arrays
      groups = authenticator.groups & self.groups
      group = groups.first
      raise ItemNotAccessibleException, "Groups intersection couldn't be find for item #{self.id} and group #{group.id}" if groups.nil? || groups.empty? || groups.length != 1
      meta = self.meta_keys.find_by(group: group)
      if meta
        decrypt self.password_crypted,
          group.private_key(authorization_user: authenticator).private_decrypt(meta.key_crypted),
          group.private_key(authorization_user: authenticator).private_decrypt(meta.iv_crypted)
      else
        raise Tarkin::ItemNotAccessibleException, "Item #{self.id} does not belongs to #{group.name}"
      end
    end
  end

  private
  def have_groups
    errors.add :item, "must belong at least to one group" if self.groups.empty?
  end
end
