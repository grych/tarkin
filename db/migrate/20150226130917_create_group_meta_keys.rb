class CreateGroupMetaKeys < ActiveRecord::Migration
  def change
    create_table :group_meta_keys do |t|
      t.binary :group_key_crypted, limit: 4096, null:false
      t.binary :group_iv_crypted,  limit: 4096, null:false
      t.belongs_to :user,  index: true
      t.belongs_to :group, index: true
      t.timestamps null: false
    end
    add_index :group_meta_keys, [:user_id, :group_id]
  end
end
