class CreateDirectories < ActiveRecord::Migration
  def change
    create_table :directories do |t|
      t.string      :name, limit: 256, null: false
      t.text        :description
      t.belongs_to  :directory, index: true

      t.timestamps null: false
    end
    add_index       :directories, :name, unique: false
    add_foreign_key :items, :directories
  end
end
