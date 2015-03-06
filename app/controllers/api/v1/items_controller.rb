class API::V1::ItemsController < Api::ApiController
  respond_to :json
  
  def show
    render json: params
    session[:dupa] = 'blada'
  end
end
