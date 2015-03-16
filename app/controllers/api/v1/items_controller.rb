class API::V1::ItemsController < Api::ApiController
  #   OS_TOKEN=`curl "http://localhost:3000/_api/v1/authorize?email=email0@example.com&password=password0"`
  #   curl --user email0@example.com:password0 "http://localhost:3000/_api/v1/items/1
  #   curl -H "Authorization: Token token=$OS_TOKEN" "http://localhost:3000/_api/v1/items/1"
  #   curl "http://localhost:3000/_api/v1/items/1?email=email0@example.com&password=password0"
  def show
    item = Item.find(params[:id])
    #render json: item.password(authorization_user: current_user)
    render json: item.username
  end
end
