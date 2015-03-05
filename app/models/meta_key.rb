# == MetaKey
# MetaKey contains the association between User and Group, and between Group and Item. For each assiciation
# it stores a crypted key (and iv as well) used to decrypt the associated values.
# * for Group, key and iv are for decrypt the Group Private Key. They are encrypted with User Public Key, so they
#   can be decrypted only with User Private Key, which means that only users associates with the Group
#   can use the group Private Key to decrypt Item.
# * for Item, key and iv are encrypted with Group Public Key. In this case, key (and iv) encrypts
#   the Items password, but to get them, you need a corresponding Group private key.
class MetaKey < ActiveRecord::Base
  belongs_to :user 
  belongs_to :group
  belongs_to :item
  # Shorter view - to prevent rails console to show all the encrypted data
  def inspect
    "#<MetaKey> id: #{self.id}  [user_id: #{self.user_id}, group_id: #{self.group_id}, item_id: #{self.item_id}]"
  end
end
