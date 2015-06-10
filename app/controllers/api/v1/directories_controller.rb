class API::V1::DirectoriesController < Api::ApiController
  include DirectoriesHelper
  # List directory structure. Returns all subdirectories and items (usernames) for the given path.
  # By default returns newline-separated text, but it could be modified by .json or .xml extension. 
  # For text output, subdirectories are followed by slash, eg. "subdir1/".
  #
  # <tt>GET|POST /_api/v1/_dir/path_to_directory*</tt>
  #
  # parameters::
  # * path to directory
  #
  # = Examples
  #   resp = conn.get("http://localhost:3000/_dir/databases", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> "{"directories":[{"name":"C84PCPY","id":5},{"name":"C84PTRN","id":6}],"items":[]}"
  #
  #   resp = conn.get("http://localhost:3000/_api/v1/_dir/databases/C84PCPY", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> "{"directories":[],"items":[{"id":1,"username":"sysadm"},{"id":2,"username":"sysman"}}"
  #
  # === Shell
  # 
  #   $ curl "http://localhost:3000/_api/v1/_dir/databases?email=email0@example.com&password=password0" 
  #   C84PCPY/
  #   C84PTRN/
  def index
    if params[:path]
      # setting the format manually, as paths may contain dots
      case File.extname(params[:path])
      when '.xml', '.text', '.json'
        request.format = File.extname(params[:path]).gsub('.', '').to_sym
        path = File.basename params[:path], File.extname(params[:path])
      else
        path = params[:path]
      end
      d = Directory.cd(path)
    else
      d = Directory.root
    end

    respond_to do |format|
      format.json { render json: directory_children(d)}
      format.xml  { render xml:  directory_children(d)}
      format.text { render text: directory_children_text(d)}
    end
  end

  # Search for Items and Directories for the given +term+ in params. Used to autocomplete in the search input box.
  # Returns JSON array of hashes: [{label: found username or directory name, redirect_to: url}], 
  # where url for Item is the name of Directory which contains it.
  #
  # <tt>GET /_api/v1/_find[.xml|.json]</tt>
  #
  # parameters::
  # * term: string to search, use asterisk * as a wildcard
  #
  # = Examples
  #   resp = conn.get("http://localhost:3000//_api/v1/_find?term=data*bases", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> [{"label":"/databases/","redirect_to":"/databases/"}]
  def find
    # items = current_user.search_items(params[:term]).order(:username).map{ |item| {category: 'Items', label: item.path, id: item.id, redirect_to: item.directory.path} }
    items = current_user.search_items(params[:term]).order(:username).map{ |item| {label: item.path, redirect_to: urlsafe_path(item.directory.path) + "##{item.id}"} }
    dirs = current_user.search_dirs(params[:term]).order(:path).map{ |dir| {label: dir.path, redirect_to: urlsafe_path(dir.path)} }
    respond_to do |format|
      format.json { render json: items + dirs}
      format.xml  { render xml:  items + dirs}
      format.text { render text: items + dirs}
    end
  end

  private
  def directory_children_text(d)
    current_user.ls_dirs(d).map{|dir| "#{dir.name}/"}.join("\n") + "\n" + current_user.ls_items(d).map{|item| item.username}.join("\n")
  end

  def directory_children(d)    
    {directories: current_user.ls_dirs(d).map {|dir| {name: dir.name, id: dir.id}}, items: current_user.ls_items(d).map {|item| {id: item.id, username: item.username}}}
  end

end
