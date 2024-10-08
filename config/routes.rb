Rails.application.routes.draw do
    resources :forms do
      member do
        get "preview"
        get "duplicate"
        patch "update_deadline"
      end
      resources :form_responses, only: [ :new, :create ]
      resources :attributes do
        member do
          patch :update_weightage
        end
      end
    end



  # Defines the root path route ("/")
  # root "posts#index"
  root "welcome#index"
  get "welcome/index", to: "welcome#index", as: "welcome"
  get "/users/:id", to: "users#show", as: "user"
  get "/logout", to: "sessions#logout", as: "logout"
  get "/auth/google_oauth2/callback", to: "sessions#omniauth"

  get "sessions/logout"
  get "sessions/omniauth"
  get "users/show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "/upload", to: "forms#upload"
  post "validate_upload", to: "forms#validate_upload"
end
