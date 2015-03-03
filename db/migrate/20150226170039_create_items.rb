class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string      :username, limit: 256, index: true
      t.binary      :password_crypted, limit: 4096
      t.belongs_to  :directory, index: true
      t.text        :description

      t.timestamps  null: false
    end
    add_foreign_key :meta_keys, :items
  end
end
