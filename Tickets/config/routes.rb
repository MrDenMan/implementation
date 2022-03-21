Rails.application.routes.draw do
  get 'tickets/price'
  post 'tickets/booking'
  delete 'tickets/:id', to: 'tickets#delete'
  put 'tickets/purchase'
  get 'tickets', to: 'tickets#show'
  put 'tickets/:id/block', to: 'tickets#block'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
