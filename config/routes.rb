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
        get :edit_notes
        patch :update_notes
        get :cancel_edit_notes
      end
      collection do
        get :bulk_add
        post :bulk_create
        get :bulk_results
      end
    end
  end
  get "dashboard", to: "alliances#show", as: :dashboard

  scope '/dashboard' do
    get '/alliance_duels', to: 'alliance/alliance_duels#index', as: :alliance_duels
    get '/alliance_duels/new', to: 'alliance/alliance_duels#new', as: :new_alliance_duel
    post '/alliance_duels', to: 'alliance/alliance_duels#create'
    
    # Custom route for the parent resource using start_date
    scope '/alliance_duels/:alliance_duel_start_date' do
      get '', to: 'alliance/alliance_duels#show', as: :alliance_duel
      
      # Nested routes for duel_days
      resources :duel_days, only: [:update], controller: 'alliance/duel_days', as: 'alliance_duel_duel_days' do
        member do
          get :edit_goal
          get :cancel_edit_goal
          patch :toggle_lock
        end
      end
      
      # Route for updating scores
      post 'scores', to: 'alliance/alliance_duels#update_score'
    end

    delete '/alliance_duels/:id', to: 'alliance/alliance_duels#destroy', as: :delete_alliance_duel
  end
end
