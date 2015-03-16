class API::V1::ItemsController < Api::ApiController
  #   OS_TOKEN=`curl "http://localhost:3000/_api/v1/authorize?email=email0@example.com&password=password0"`
  #   curl --user email0@example.com:password0 "http://localhost:3000/_api/v1/items/1
  #   curl -H "Authorization: Token token=$OS_TOKEN" "http://localhost:3000/_api/v1/items/1"
  #   curl "http://localhost:3000/_api/v1/items/1?email=email0@example.com&password=password0"
  def show
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
    
    respond_to do |format|
      format.json { render json: item_data(item)}
      format.xml  { render xml:  item_data(item)}
      format.text { render text: item.password(authorization_user: current_user)}
    end
  end

  private
  def item_data(item)
    {username: item.username, password: item.password(authorization_user: current_user)}
  end
end
