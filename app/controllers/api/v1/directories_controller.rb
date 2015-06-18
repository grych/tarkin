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
        path = params[:path].sub(/#{Regexp.escape(File.extname(params[:path]))}$/, '')
      else
        path = params[:path]
      end
      begin
        d = Directory.cd(path)
      rescue Tarkin::DirectoryNotFound => e
        raise ActionController::RoutingError.new('Not Found')
      end
    else
      d = Directory.root
    end

    respond_to do |format|
      format.json { render json: directory_children(d)}
      format.xml  { render xml:  directory_children(d)}
      format.text { render text: directory_children_text(d)}
    end
  end

  # Returns true if the server is available and user is autorized
  #
  #   curl -H "Authorization: Token token=$OS_TOKEN" "http://localhost:3000/_api/v1/_ping"
  def ping
    render json: true
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
    {
      directories: current_user.ls_dirs(d).map {|dir| {name: dir.name, id: dir.id, created_at: dir.created_at, updated_at: dir.updated_at, description: dir.description}}, 
      items: current_user.ls_items(d).map {|item| {id: item.id, username: item.username, created_at: item.created_at, updated_at: item.updated_at, description: item.description}}
    }
  end

end
