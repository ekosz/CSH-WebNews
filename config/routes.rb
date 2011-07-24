Webnews::Application.routes.draw do
  root :to => 'pages#main'
  get '/home', :to => 'pages#main'
  
  get '/preferences',           :to => 'users#edit',    :as => :edit_user
  put '/preferences',           :to => 'users#update',  :as => :update_user
  
  get '/compose',               :to => 'posts#new',     :as => :new_post
  post '/compose',              :to => 'posts#create',  :as => :create_post
  
  constraints :newsgroup => /[^\/]*/ do
    get '/:newsgroup/index',      :to => 'posts#index',   :as => :posts
    get '/:newsgroup/:number',    :to => 'posts#show',    :as => :post
    delete '/:newsgroup/:number', :to => 'posts#destroy', :as => :destroy_post
  end
end
