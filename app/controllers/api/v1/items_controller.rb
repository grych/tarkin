class API::V1::ItemsController < Api::ApiController
  def show
    render json: params
  end
end
