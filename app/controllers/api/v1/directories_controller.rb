class API::V1::DirectoriesController < Api::ApiController
  # List directory structure. Returns all subdirectories and items (usernames) for the given path.
  # By default returns newline-separated text, but it could be modified by .json or .xml extension. 
  # For text output, subdirectories are followed by slash, eg. "subdir1/".
  #
  # <tt>GET|POST /_api/v1/_dir/path_to_directory*[.xml|.json]</tt>
  #
  # parameters::
  # * User email and password as GET/POST parameters, or
  # * basic http authentication in header, or
  # * auth token in header: <tt>Authorization: Token token=$TOKEN</tt>
  #
  # = Examples
  #   resp = conn.get("http://localhost:3000/_dir/databases", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> "C84PCPY/\nC84TRN/"
  #
  #   resp = conn.get("http://localhost:3000/_dir/databases.json", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> "{"directories":[{"name":"C84PCPY","id":5},{"name":"C84PTRN","id":6}],"items":[]}"
  #
  #   resp = conn.get("http://localhost:3000/_dir/databases/C84PCPY.json", email: "email0@example.com", password="password0")
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
      d = Directory.cd(params[:path])
    else
      d = Directory.root
    end
    respond_to do |format|
      format.json { render json: directory_children(d)}
      format.xml  { render xml:  directory_children(d)}
      format.text { render text: directory_children_text(d)}
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
