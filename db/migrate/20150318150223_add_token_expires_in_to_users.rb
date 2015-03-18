class AddTokenExpiresInToUsers < ActiveRecord::Migration
  def change
    add_column :users, :token_expires_in, :integer, default: 30
    add_column :users, :admin, :boolean, default: false
    add_index  :users, :admin, unique: false
  end
end
