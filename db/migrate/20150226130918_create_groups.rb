class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name, limit: 256, null: false
      t.string :public_key_pem, limit: 4096, null: false
      t.binary :private_key_pem_crypted, limit: 4096, null: false

      t.timestamps null: false
    end
    add_index :groups, :name, unique: true
    add_foreign_key :meta_keys, :groups
  end
end
