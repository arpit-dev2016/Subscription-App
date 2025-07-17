Rails.application.routes.draw do
  get "webhooks/receive"
  get "dashboard/index"
  resource :session
  resources :passwords, param: :token
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"
  post "create-checkout-session", to: "stripe_webhooks#create_checkout_session"
  post '/webhooks/stripe', to: 'stripe_webhooks#webhook'
  get '/invoices/:session_id', to: 'invoices#show', as: :download_invoice
  post '/stripe_webhooks/cancel', to: 'stripe_webhooks#cancel'
end
