class API::V1::SessionsController < Api::ApiController
  include SessionsHelper
  #   OS_TOKEN=`curl "http://localhost:3000/_api/v1/authorize?email=email0@example.com&password=password0"`
  def create
    render json: @token
  end
end
