Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ] do
    post :demo
    post :reset_demo
  end
  resources :registrations, only: [ :new, :create ]
  resource :dashboard, only: :show do
    post :quick_log_missed
    post :quick_log_makeup
  end
  resource :history, only: :show
  resource :onboarding, only: [ :show, :create ]
  resource :owed, only: :show, controller: :owed_details
  resource :makeup, only: :show, controller: :makeup_details
  resource :missed, only: :show, controller: :missed_details
  resources :missed_fasts
  resources :ramadan_season_balances
  resources :makeup_fasts

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#show"
end
