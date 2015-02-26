# == Schema Information
#
# Table name: group_meta_keys
#
#  id                :integer          not null, primary key
#  group_key_crypted :binary           not null
#  group_iv_crypted  :binary           not null
#  user_id           :integer
#  group_id          :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class GroupMetaKey < ActiveRecord::Base
  belongs_to :user 
  belongs_to :group
end
