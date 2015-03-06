module DirectoriesHelper
  def relative_link_to_directory(directory)
    link_to "#{directory.name}", "#{File.join request.path, directory.name}"
  end
  def link_to_directory(directory)
    path = directory.pwd_r.map{|x| x.name}.join "/"
    link_to directory.name, "/#{path}"
  end
end
