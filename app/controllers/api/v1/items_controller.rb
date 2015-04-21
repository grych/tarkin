class API::V1::ItemsController < Api::ApiController
  # Retrieve the password using the Item id or full path to the item. Returns text for password by default, but 
  # it can return XML or JSON using the extensions. In that case it will return the hash containg the username, the password
  # and the item ID. 
  #
  # <tt>GET|POST /_api/v1/_password/:item_id[.xml|.json]</tt>
  # 
  # <tt>GET|POST /_api/v1/path_to_item*[.xml|.json]</tt>
  #
  # parameters::
  # * item_id
  # * path to the password (all directories separated by slash, followed by username)
  #
  # = Examples
  #   resp = conn.get("http://localhost:3000/_api/v1/_password/1", email: "email0@example.com", password="password0")
  #   password = resp.body if resp.status == 200
  #   #=> "secret"
  #
  #   resp = conn.get("http://localhost:3000/_api/databases/C84PCPY/scott", email: "email0@example.com", password="password0")
  #   password = resp.body if resp.status == 200
  #   #=> "tiger"
  #
  #   resp = conn.get("http://localhost:3000/_api/databases/C84PCPY/scott.json", email: "email0@example.com", password="password0")
  #   resp.body
  #   #=> "{"username":"scott","password":"tiger"}"
  #
  # === Shell
  # [via get] <tt>PASSWORD=`curl "http://localhost:3000/_api/v1/_password/1?email=email0@example.com&password=password0"`</tt>
  # [via http authentication] <tt>PASSWORD=`curl --user email0@example.com:password0 "http://localhost:3000/_api/v1/_password/1"`</tt>
  # [with token] 
  #    <tt>OS_TOKEN=`curl "http://localhost:3000/_api/v1/_authorize?email=email0@example.com&password=password0"`</tt>
  #
  #    <tt>PASSWORD=`curl -H "Authorization: Token token=$OS_TOKEN" "http://localhost:3000/_api/v1/password/1"`</tt>
  # [using path instead of id] <tt>PASSWORD=`curl "http://localhost:3000/_api/databases/C84PCPY/sysadm?email=email0@example.com&password=password0"`</tt>
  def show
    logger.debug " ---------- params: #{params}"
    if params[:id]
      item = Item.find(params[:id])
    elsif params[:path]
      dir = File.dirname(params[:path])
      if dir == "/" || dir == "."
        d = Directory.root
      else
        d = Directory.cd(dir)
      end
      b = File.basename(params[:path])
      item = d.items.find_by(username: b)
    end
    if item.password(authorization_user: current_user)
      respond_to do |format|
        format.json { render json: item_data(item)}
        format.xml  { render xml:  item_data(item)}
        format.text { render text: item.password(authorization_user: current_user)}
      end
    else
      respond_to do |format|
        format.text { render text: 'unprocessable', status: :unprocessable_entity }
        format.json { render text: {status: 'unprocessable'}, status: :unprocessable_entity }
        format.xml  { render text: {status: 'unprocessable'}, status: :unprocessable_entity }
      end
    end
  end
  private
  def item_data(item)
    {id: item.id, username: item.username, password: item.password(authorization_user: current_user)}
  end
end
