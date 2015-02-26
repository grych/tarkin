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
  has_many :meta_keys
  validates :password_crypted, presence: true

  def password=(pwd)
    @password = pwd if new_record?
  end

  def password
    @password || (raise PasswordNotAccessibleException, "Password can't be accessed at this moment")
  end
end
