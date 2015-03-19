class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.belongs_to :user, index: true
      t.belongs_to :directory, index: true
    end
    add_index :favorites, [:user_id, :directory_id]
    add_foreign_key :favorites, :users
    add_foreign_key :favorites, :directories
  end
end
