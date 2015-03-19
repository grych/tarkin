class AddPathToDirectories < ActiveRecord::Migration
  def change
    add_column :directories, :path, :string, limit: 4096
    add_index  :directories, :path, unique: true
  end
end
