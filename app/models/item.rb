# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  password_crypted :binary
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class PasswordNotAccessibleException < Exception; end
class Item < ActiveRecord::Base
  has_many :meta_keys, dependent: :destroy
  has_many :groups, through: :meta_keys
  validates :password_crypted, presence: true

  def password=(pwd)
    @password = pwd if new_record?
  end

  def password(user=nil)
   raise PasswordNotAccessibleException, "Password can't be accessed at this moment" if !new_record? && user.nil? 
    if new_record?
      @password
    else
      user.item_password(self)
    end
  end
end
