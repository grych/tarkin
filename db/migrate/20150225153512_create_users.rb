class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, limit: 256, null: false
      t.string :public_key_pem, limit: 4096, null: false
      t.binary :private_key_pem_crypted, limit: 4096, null: false
      t.binary :iv, limit: 4096, null: false
      t.timestamps null: false
    end
  end
end
