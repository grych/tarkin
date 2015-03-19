Rails.application.routes.draw do
  scope '_sessions' do
    resources :sessions, only: [:new, :create]
    match '/signout', to: 'sessions#destroy',     via: 'delete'
    #match '/signin',  to: 'sessions#new',         via: 'get'
  end
  scope '_aj' do
    post 'ok_with_cookies', to: 'directories#ok_with_cookies'
    post 'switch_favorite', to: 'directories#switch_favorite'
  end
  namespace :api, path: "_api", defaults: {format: :json} do
    namespace :v1 do
      #resources :sessions, only: [:new]
      #resources :items, only: [:show], defaults: {format: :text}, via: ['get', 'post']  #/items/item_id
      match '_authorize',    to: 'sessions#create',  defaults: {format: :text}, via: ['get', 'post']
      match '_password/:id', to: 'items#show',       defaults: {format: :text}, via: ['get', 'post']
      match '_dir',          to: 'directories#index',defaults: {format: :text}, via: ['get', 'post']
      match '_dir/*path',    to: 'directories#index',defaults: {format: :text}, via: ['get', 'post']
      match '*path',         to: 'items#show',       defaults: {format: :text}, via: ['get', 'post']
    end
  end

  get '*path' => 'directories#show'
  #resources :directories, path: "", only: [:index, :new, :show, :create, :destroy]
  root 'directories#show'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
