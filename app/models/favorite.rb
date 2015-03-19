class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :directory
  belongs_to :item
end
