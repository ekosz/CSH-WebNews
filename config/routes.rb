Webnews::Application.routes.draw do
  root :to => 'pages#home'
  get '/home', :to => 'pages#home'
  get '/new_user', :to => 'pages#new_user'
  get '/check_new', :to => 'pages#check_new'
  get '/mark_read', :to => 'pages#mark_read'
  
  get '/settings',              :to => 'users#edit',    :as => :edit_user
  put '/settings',              :to => 'users#update',  :as => :update_user
  
  get '/compose',               :to => 'posts#new',     :as => :new_post
  post '/compose',              :to => 'posts#create',  :as => :create_post
  
  constraints :newsgroup => /[^\/]*/ do
    get '/:newsgroup/index',      :to => 'posts#index',   :as => :posts
    get '/:newsgroup/:number',    :to => 'posts#show',    :as => :post
    delete '/:newsgroup/:number', :to => 'posts#destroy', :as => :destroy_post
  end
end
