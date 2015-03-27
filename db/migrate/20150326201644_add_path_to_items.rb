class AddPathToItems < ActiveRecord::Migration
  def change
    add_column :items, :path, :string, limit: 4096
    add_index  :items, :path, unique: true
  end
end
