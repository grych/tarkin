class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.binary :password_crypted, limit: 4096

      t.timestamps null: false
    end
    add_foreign_key :meta_keys, :items
  end
end
