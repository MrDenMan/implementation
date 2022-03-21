Rails.application.routes.draw do

  get 'events/:id', to: 'events#show'   
  put 'events/:id', to: 'events#update'  
  delete 'events/:id', to: 'events#destroy'
  put 'events/:id/entrance', to: 'events#entrance'
  post 'events', to: 'events#update'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
