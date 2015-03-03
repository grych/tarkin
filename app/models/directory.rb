require 'validators/directory_validator'

# == Directory
# 
# Directory groups Items (passwords) for user interface purposes
class Directory < ActiveRecord::Base
  include ActiveModel::Validations

  VALID_DIRECTORY_REGEX = /\A[^\/\*\n]+\z/    # directory name can't contain slash and asterisk and newline
  has_many :items
  has_many :directories
  belongs_to :directory

  after_initialize -> { self.name.strip! }
  validates_with DirectoryValidator
  validates :name, presence: true, format: { with: VALID_DIRECTORY_REGEX }

  # The root of all directories is the one without the parent
  # 
  #   root = Directory.root
  def self.root
    Directory.find_by(directories: nil) || (raise(Tarkin::DirectoryNotFound, "Root not found") unless Directory.count == 0)
  end

  # Is the current directory the root?
  # 
  #  Directory.root.root?  #=> true
  def root?
    self.directory.nil?
  end

  # Parent of current directory
  #
  #   Directory.root.parent  #=> nil
  def parent
    self.directory
  end

  # Create the directory under current dir. If it already exists, just returns it
  #
  #   Directory.root.mkdir "new dir", description: "The brand new one"
  #   #=> #<Directory:0x007f8ba7c6063, id: 16, name: "new dir", description: "The brand new one">
  def mkdir(name, **options)
    Directory.find_or_create_by!(name: name, directory: self, **options)
  end

  # Create a bunch of directories (equivalent to Unix 'mkdir -p') separated by slash.
  # Returns last of them.
  #
  #   d.mkdir_p 'usr/local/bin' #=> #<Directory:0x007f8ba57c9ce id: 15, name: "bin">
  def mkdir_p(path, **options)
    r = self
    path.split('/').reject(&:empty?).each do |dir|
      r = r.mkdir(dir, **options)
    end
    r
  end

  # Creates a bunch of directories starting with root
  #
  #   Directory.mkdir_p '/Users/grych'
  def self.mkdir_p(path, **options)
    Directory.root.mkdir_p(path, **options)
  end

  # Find a directory belongs to current directory. If the path starts with '/', it keeps searching
  # from the root.
  #
  #   directory.cd('path/user')   #=> #<Directory:0x007f8ba57c9ce id: 15, name: "user">
  #   directory.cd('/path/user')  #=> #<Directory:0x007f8ba57c9ce id: 15, name: "user">
  def cd(path)
    r = if path.strip.starts_with?('/') then Directory.root else self end
    path.split('/').reject(&:empty?).each do |dir|
      r = r.directories.find_by(name: dir)
      raise Tarkin::DirectoryNotFound, "Directory #{dir} not found" unless r
    end
    r
  end

  # Find a directory, starting from root. Equivalent for #cd("/path") instance method
  # 
  #   Directory.cd('path/user') == directory.cd('/path/user')  #=> true
  def self.cd(path)
    Directory.root.cd(path)
  end

  # # Childred of current directories is the collection of directories 
  # def children
  #   self.directories
  # end

  # # Siblings are all directories in the same level except self
  # def siblings
  #   self.parent.children - [self]
  # end

  private
  def root_not_exists?
    if self.directories.empty?
      false
    else
      !Directory.root.nil?
    end
  end
end
