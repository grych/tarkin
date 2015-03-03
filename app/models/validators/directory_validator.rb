class DirectoryValidator < ActiveModel::Validator
  def validate(record)
    # trying to create another root
    if Directory.root && !record.directory
      record.errors[:root] << 'duplicated'
    end
    # trying to add directory with the same name in the same parent directory
    if !record.root? && record.parent.directories.find_by(name: record.name)
      record.errors[:directory] << 'name not unique'
    end
  end
end
