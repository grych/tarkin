class CreateMetaKeys < ActiveRecord::Migration
  def change
    create_table :meta_keys do |t|
      t.binary :key_crypted, limit: 4096, null:false
      t.binary :iv_crypted,  limit: 4096, null:false
      t.belongs_to :user,  index: true
      t.belongs_to :group, index: true
      t.belongs_to :item,  index: true
      t.timestamps null: false
    end
    add_index :meta_keys, [:user_id, :group_id], unique: true
    add_index :meta_keys, [:group_id, :item_id], unique: true
  end
end
