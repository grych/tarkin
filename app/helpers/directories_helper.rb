module DirectoriesHelper
  def relative_link_to_directory(directory, **options)
    # link_to "#{if options[:show] then options[:show] else directory.name+"/" end}", "#{File.join request.path, directory.name}"
    link_to "#{if options[:show] then options[:show] else directory.name+"/" end}", directory.path
  end

  def link_to_parent_directory(directory, **options)
    unless directory.root?
      # path = directory.parent.pwd_r.map{|x| x.name}.join "/"
      # link_to "..", "/#{path}", **options
      link_to '..', directory.parent.path, **options
    end
  end

  def link_to_directory(directory, **options)
    # path = directory.pwd_r.map{|x| x.name}.join "/"
    # link_to "#{directory.name}", "/#{path}", **options
    link_to directory.name, directory.path, **options
  end

  def groups_for_directory(directory)
    directory.groups.map{|group| group.name}.join(', ')
  end

  def groups_for_item(item)
    item.groups.map{|group| group.name}.join(', ')
  end
end
