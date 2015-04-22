class AddFirstNameAndLastNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :first_name, :string, limit: 256
    add_column :users, :last_name, :string, limit: 256
    remove_column :users, :name, :string, limit: 256
    add_index  :users, :last_name, unique: false
  end
end
