class DirectoryValidator < ActiveModel::Validator
  def validate(record)
    # trying to create another root
    if Directory.root && !record.directory
      record.errors[:root] << 'there can be only one'
    end
    # trying to add directory with the same name in the same parent directory
    if !record.root? && record.siblings.find_by(name: record.name) 
      record.errors[:name] << 'not unique'
    end
    # if !record.root? && record.groups.empty?
    #   record.errors[:directory] << 'must belong to at least one group'
    # end
  end
end
