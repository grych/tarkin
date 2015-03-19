class AddItemToFavorites < ActiveRecord::Migration
  def change
    add_column :favorites, :item_id, :integer
    add_index  :favorites, :item_id
    add_index  :favorites, [:user_id, :item_id]
    add_foreign_key :favorites, :items
  end
end
