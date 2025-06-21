Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "signup", to: "users#new", as: :signup
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  resources :users, only: [ :create ]

  get "profile", to: "users#show", as: :profile

  resources :alliances, only: [ :new, :create ] do
    resources :players, only: [ :index, :new, :create, :edit, :update, :destroy ], controller: "alliance/players" do
      member do
        patch :toggle_active
      end
      collection do
        get :bulk_add
        post :bulk_create
        get :bulk_results
      end
    end
  end
  get "dashboard", to: "alliances#show", as: :dashboard
end
