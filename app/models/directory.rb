require 'validators/directory_validator'

# == Directory
# 
# Directory groups Items (passwords) for user interface purposes
class Directory < ActiveRecord::Base
  include ActiveModel::Validations

  # VALID_DIRECTORY_REGEX = /\A[^\/\*\n]+\z/    # directory name can't contain slash and asterisk and newline
  VALID_DIRECTORY_REGEX = /\A[^_][^\/\*\n]+(?<!\.xml|\.text|\.json)\z/
  has_many   :items
  has_many   :directories
  # has_many   :users, through: :favorites
  belongs_to :directory
  has_and_belongs_to_many :groups, -> { uniq }

  after_initialize -> { self.name.strip! if name }
  before_validation :update_path
  validates_with DirectoryValidator
  validates :name, presence: true, format: { with: VALID_DIRECTORY_REGEX }, length: { maximum: 256 }
  validates :path, presence: true, length: { maximum: 4096 }, uniqueness: true
  before_destroy :check_children

  # default_scope { order('name ASC') }

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

  # Groups of current Directory.
  # In the special case, when Directory is root, returns all groups OR all groups for a given user
  #
  #   Directory.root.groups.count                     #=> 15
  #   Directory.root.groups(user: User.first).count   #=> 2
  #   directory.groups.count                          #=> 2
  alias_method :groups_old, :groups
  def groups(**options)
    if options[:user]
      options[:user].groups
    else
      if self.root?
        Group.all
      else
        self.groups_old
      end
    end
  end

  # Create the directory under current dir. If it already exists, just returns it.
  # New directory inherits groups from the parent. If creating directory is under root,
  # User can be given as an option (in this case it inherits only Users groups).
  # It is also possible to specify list of groups which should be connected with the
  # new directory by adding options[:groups]
  #
  #   Directory.root.mkdir "new dir", description: "The brand new one", user: User.first
  #   #=> #<Directory:0x007f8ba7c6063, id: 16, name: "new dir", description: "The brand new one">
  def mkdir(name, **options)
    user = nil
    if options[:user]
      user = options[:user]
      options.delete :user
    end
    groups = nil
    if options[:groups]
      groups = options[:groups]
      options.delete :groups
    end
    d = Directory.new(name: name, directory: self, **options)
    if user || groups
      # inherits groups from user
      self.groups(user: user).each { |group| d.groups << group  } if user
      # take the groups from the list
      groups.each { |group| d.groups << group  } if groups
    else 
      # inherit all groups from parent
      self.groups.each do |group|
        d.groups << group
      end
    end
    d
  end

  def mkdir!(name, **options)
    d = Directory.find_by(name: name, directory: self)
    unless d
      d = self.mkdir(name, **options)
      d.save!
    end
    d
  end

  # Create a bunch of directories (equivalent to Unix 'mkdir -p') separated by slash.
  # Returns last of them.
  #
  #   d.mkdir_p 'usr/local/bin' #=> #<Directory:0x007f8ba57c9ce id: 15, name: "bin">
  def mkdir_p!(path, **options)
    r = self
    path.split('/').reject(&:empty?).each do |dir|
      r = r.mkdir!(dir, **options)
    end
    r
  end

  # Creates a bunch of directories starting with root
  #
  #   Directory.mkdir_p '/Users/grych'
  def self.mkdir_p!(path, **options)
    d = Directory.root.mkdir_p!(path, **options)
    Directory.root.reload
    d
  end

  # Find a directory belongs to current directory. If the path starts with '/', it keeps searching
  # from the root.
  #
  #   directory.cd('path/user')   #=> #<Directory:0x007f8ba57c9ce id: 15, name: "user">
  #   directory.cd('/path/user')  #=> #<Directory:0x007f8ba57c9ce id: 15, name: "user">
  def cd(path)
    return Directory.root if path.nil? || path.empty?
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

  # Children of current directories is the collection of directories 
  # def children
  #   self.directories
  # end

  # Siblings are all directories in the same level except self
  def siblings
    self.parent.directories.where.not(id: self.id)
  end

  # See #list
  def _list(depth=0)
    ret = "  " * depth + self.name + "/" + " [" + self.groups.map{|g| g.name}.join(', ') + "]\n"
    self.directories.each {|child| ret += child._list(depth + 1)} 
    self.items.each { |item| ret += "  " * depth + "  " + item.username + "\n" }
    ret
  end

  # Prints all items and directories belongs to the current directory
  #
  #   d.list
  #   #=>  dir0/ [group 0, group 1]
  #   #=>    subdir/ []
  #   #=>    username 0
  def list
    self.reload
    puts _list 0
  end

  # Line #list, but lists everything starting from root.
  def self.list
    puts Directory.root.list
  end

  # Returns a list of ancestrors of current directory, without root
  def pwd_r(array=[])
    if self.parent.nil?
      array.reverse
    else
      self.parent.pwd_r(array + [self])
    end
  end

  # Like #pwd_r, but including root
  def pwd
    [Directory.root] + pwd_r
  end

  # Shorter view
  def inspect
    "#<Directory> '#{self.name}'  [id: #{self.id}, parent: #{self.directory_id}]"
  end

  private
  def update_path
    self.path = "#{unless self.root? then pwd.map{|dir| dir.name if not dir.root?}.join('/') end}/"
  end

  def root_not_exists?
    if self.directories.empty?
      false
    else
      !Directory.root.nil?
    end
  end

  def check_children
    if !self.directories.empty? && !self.items.empty?
      self.errors[:directory] << "is not empty"
      return false
    end
  end
end
