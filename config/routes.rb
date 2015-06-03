Rails.application.routes.draw do
  scope '_sessions' do
    resources :sessions, only: [:new, :create]
    match '/signout', to: 'sessions#destroy',     via: 'delete'
    #match '/signin',  to: 'sessions#new',         via: 'get'
  end
  scope '_aj' do
    post 'ok_with_cookies', to: 'directories#ok_with_cookies'
    post 'switch_favorite', to: 'directories#switch_favorite'
    #post 'dir',           to: 'directories#create'
    resources :directories, only: [:create, :update, :edit, :new, :destroy]
    resources :items,       only: [:create, :update, :edit, :new, :destroy]
    get 'profile', to: 'directories#profile'
    post 'update_profile', to: 'directories#update_profile'
  end
  scope '_dir' do
    match 'search', to: 'directories#search', via: ['post']
  end
  namespace :api, path: "_api", defaults: {format: :json} do
    namespace :v1 do
      match '_find',         to: 'directories#find', defaults: {format: :json}, via: ['get']
      match '_authorize',    to: 'sessions#create',  defaults: {format: :text}, via: ['get', 'post']
      match '_password/:id', to: 'items#show', as: '_password', defaults: {format: :text}, via: ['get', 'post']
      match '_dir',          to: 'directories#index',defaults: {format: :text}, via: ['get', 'post']
      match '_dir/*path',    to: 'directories#index',defaults: {format: :text}, via: ['get', 'post']
      match '*path',         to: 'items#show',       defaults: {format: :text}, via: ['get', 'post']
    end
  end
  scope '_admin', module: :admin do
    resources :groups
    resources :users
  end

  get '*path' => 'directories#show'
  root 'directories#show'
end
