Rails.application.routes.draw do
  resources :customers, only: %i[create show]
  get "pix", to: "pix#show"
end
